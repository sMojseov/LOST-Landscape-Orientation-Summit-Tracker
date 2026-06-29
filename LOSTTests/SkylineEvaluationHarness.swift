// SkylineEvaluationHarness.swift
// LOSTTests — Chapter 4 Thesis Evaluation
//
// HOW TO RUN
// ──────────────────────────────────────────────────────────────────────────
// Preferred (native ARM, full 720-pt DEM):
//   Run from Xcode on Stefan's iPhone — Product › Test › SkylineMatcherEvaluation
//
// Simulator fallback (auto-switches to 72-pt DEM for speed):
//   xcodebuild test -project LOST.xcodeproj -scheme LOST \
//     -destination 'platform=iOS Simulator,arch=arm64,name=iPhone 17' \
//     -only-testing LOSTTests/SkylineMatcherEvaluation
//
// OUTPUTS
// ──────────────────────────────────────────────────────────────────────────
// • ~/Documents/evaluation_results.csv  (all per-trial rows)
// • Console: summary statistics + markdown performance table
//
// NOTE ON DEM RESOLUTION
// ──────────────────────────────────────────────────────────────────────────
// On device the matcher DEM uses 720 points (0.5°/step) — identical to the
// production DEMSkylineRenderer output.  In the iOS simulator each match()
// call's O(n) linear DEM scan makes 720-pt experiments impractical (~3 min);
// we automatically switch to 72 points (5°/step).  Peak positions / widths
// are faithfully represented at both resolutions; qualitative accuracy
// trends are identical.  Label in CSV: dem_step_count column.

import XCTest
import CoreLocation
import Darwin          // mach_task_basic_info
@testable import LOST

// =============================================================================
// MARK: – DEM resolution switch
// =============================================================================

// Production: 720 pts (0.5°/step).  Simulator: 72 pts (5°/step, 10× faster).
#if targetEnvironment(simulator)
private let kDEMStepCount = 72
private let kDEMStepDeg   = 5.0
private let kDEMResLabel  = "72-pt DEM (5°/step, simulator mode)"
#else
private let kDEMStepCount = 720
private let kDEMStepDeg   = 0.5
private let kDEMResLabel  = "720-pt DEM (0.5°/step, production)"
#endif

// =============================================================================
// MARK: – Seeded PRNG  (64-bit LCG + Box-Muller Gaussian)
// =============================================================================

private struct RNG {
    private var s: UInt64

    init(seed: UInt64 = 42) {
        s = seed &* 6364136223846793005 &+ 1442695040888963407
    }

    mutating func nextDouble() -> Double {
        s = s &* 6364136223846793005 &+ 1442695040888963407
        return Double(s >> 11) * (1.0 / Double(UInt64(1) << 53))
    }

    mutating func gaussian(std: Double) -> Double {
        let u1 = max(nextDouble(), 1e-300)
        let u2 = nextDouble()
        return std * sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
    }

    mutating func nextInt(_ n: Int) -> Int {
        Int(nextDouble() * Double(n))
    }
}

// =============================================================================
// MARK: – Alpine reference DEM  (deterministic, no PRNG)
// =============================================================================

// Generates `stepCount` SkylinePoints at `stepDeg` resolution.
// Five Gaussian peaks on a smooth undulating base; elevation clipped to [0,15]°.
private func makeAlpineProfile(stepCount: Int = kDEMStepCount,
                                stepDeg:   Double = kDEMStepDeg) -> [SkylinePoint] {
    func gauss(_ b: Double, c: Double, h: Double, σ: Double) -> Double {
        var d = abs(b - c)
        if d > 180 { d = 360 - d }
        return h * exp(-0.5 * pow(d / σ, 2))
    }

    return (0 ..< stepCount).map { step in
        let b   = Double(step) * stepDeg
        let rad = b * .pi / 180.0
        let base = 2.5
            + 1.2 * sin(rad * 1.0 + 0.30)
            + 0.7 * cos(rad * 2.0 + 1.10)
            + 0.4 * sin(rad * 4.0 + 2.50)
        let peaks = gauss(b, c:  42, h: 10.5, σ: 11)
                  + gauss(b, c: 128, h:  7.0, σ: 16)
                  + gauss(b, c: 205, h: 13.0, σ:  9)
                  + gauss(b, c: 292, h:  5.5, σ: 20)
                  + gauss(b, c: 338, h:  8.5, σ: 13)
        return SkylinePoint(
            bearingDegrees:        b,
            elevationAngleDegrees: max(0.0, min(15.0, base + peaks)),
            distanceKm:            20.0 + 8.0 * sin(rad * 3.0 + 1.0)
        )
    }
}

// =============================================================================
// MARK: – DEM interpolation  (for ground-truth vision profile generation)
// =============================================================================

// Linear interpolation with wrap-around on a uniform-step DEM array.
private func demElevAt(bearing: Double, dem: [SkylinePoint],
                        stepDeg: Double = kDEMStepDeg) -> Double {
    let n   = dem.count
    let idx = bearing / stepDeg
    let lo  = Int(idx) % n
    let hi  = (lo + 1) % n
    let t   = idx - floor(idx)
    return dem[lo].elevationAngleDegrees * (1.0 - t)
         + dem[hi].elevationAngleDegrees * t
}

// =============================================================================
// MARK: – Vision-profile factory
// =============================================================================

// Creates a VisionSkylineProfile simulating a camera with true heading
// = heading + trueOffset while the magnetometer reports `heading`.
// Noise σ (degrees) added per sample; optional contiguous occlusion block.
// Elevations normalised with the same DEM global min/max that normaliseDEM()
// uses, ensuring apples-to-apples comparison inside the matcher.
private func makeVisionProfile(
    dem:         [SkylinePoint],
    heading:     Double,
    trueOffset:  Double,
    sigma:       Double,
    occFraction: Double = 0.0,
    rng:         inout RNG,
    demMin:      Double,
    demMax:      Double
) -> VisionSkylineProfile {

    let hFOV   = 60.0
    let nCols  = 120
    let demRng = max(demMax - demMin, 1e-9)

    let nOcc   = Int(Double(nCols) * occFraction)
    let oStart = nOcc > 0 ? rng.nextInt(nCols - nOcc) : 0
    let oEnd   = oStart + nOcc

    var bearings:   [Double] = []
    var elevations: [Double] = []

    for col in 0 ..< nCols {
        let nx   = (Double(col) + 0.5) / Double(nCols)
        let bOff = (nx - 0.5) * hFOV

        // Vision bearing (magnetometer frame)
        let vBearing = (heading + bOff + 360).truncatingRemainder(dividingBy: 360)
        // DEM bearing the camera actually sees
        let dBearing = (heading + trueOffset + bOff + 360).truncatingRemainder(dividingBy: 360)

        var elevAngle: Double
        if nOcc > 0 && col >= oStart && col < oEnd {
            elevAngle = demMin   // occluded → horizon level
        } else {
            elevAngle = demElevAt(bearing: dBearing, dem: dem)
            if sigma > 0 { elevAngle += rng.gaussian(std: sigma) }
        }

        bearings.append(vBearing)
        elevations.append(max(0.0, min(1.0, (elevAngle - demMin) / demRng)))
    }

    return VisionSkylineProfile(bearings: bearings, elevations: elevations)
}

// =============================================================================
// MARK: – Statistics
// =============================================================================

private func stats(_ xs: [Double]) -> (mean: Double, median: Double, p95: Double) {
    guard !xs.isEmpty else { return (0, 0, 0) }
    let s = xs.sorted()
    let n = s.count
    return (
        xs.reduce(0, +) / Double(n),
        s[n / 2],
        s[max(0, Int(ceil(Double(n) * 0.95)) - 1)]
    )
}

// =============================================================================
// MARK: – Timing
// =============================================================================

private func medianMs(runs: Int = 10, block: () -> Void) -> Double {
    var times: [Double] = []
    for _ in 0 ..< runs {
        let t = Date()
        block()
        times.append(-t.timeIntervalSinceNow * 1_000.0)
    }
    return times.sorted()[times.count / 2]
}

// =============================================================================
// MARK: – Synthetic SRTM tile builder
// =============================================================================

private func syntheticHGT(gridSize: Int, elevation: Int16 = 900) -> Data {
    let count = gridSize * gridSize * 2
    var data  = Data(count: count)
    let be    = elevation.bigEndian
    data.withUnsafeMutableBytes { ptr in
        let buf = ptr.bindMemory(to: Int16.self)
        for i in 0 ..< gridSize * gridSize { buf[i] = be }
    }
    return data
}

// =============================================================================
// MARK: – CSV row
// =============================================================================

private struct EvalRow {
    let experiment:  String
    let sigma:       Double
    let trueOffset:  Double
    let occPct:      Double
    let recovered:   Double
    let qScore:      Double
    let absError:    Double
    let accepted:    Bool

    var csv: String {
        String(format: "%@,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%d",
               experiment, sigma, trueOffset, occPct,
               recovered, qScore, absError, accepted ? 1 : 0)
    }
}

// =============================================================================
// MARK: – Evaluation suite
// =============================================================================

final class SkylineMatcherEvaluation: XCTestCase {

    private static let H:         Double   = 180.0
    private static let hFOV:      Double   = 60.0
    private static let noises:    [Double] = [0.0, 0.1, 0.25, 0.5, 1.0, 2.0]
    private static let offsets:   [Double] = [-25,-20,-15,-10,-5,-2,0,2,5,10,15,20,25]
    private static let trialsA  = 20
    private static let trialsB  = 50
    private static let trialsC  = 20
    private static let occFracs: [Double] = [0.0, 0.10, 0.25, 0.40, 0.60]

    // =========================================================================
    // MARK: – Exp A + B + C  →  evaluation_results.csv
    // =========================================================================

    func testFullEvaluation() {
        executionTimeAllowance = 3600   // override 25-s XCTest default
        let done = expectation(description: "experiments_complete")
        var failures: [String] = []

        DispatchQueue.global(qos: .userInitiated).async {
            do   { try self.runExperiments(failures: &failures) }
            catch { failures.append(error.localizedDescription) }
            done.fulfill()
        }

        waitForExpectations(timeout: 3600)
        for msg in failures { XCTFail(msg) }
    }

    // Single-iteration smoke test: verifies background-queue plumbing + match()
    func testProbe() {
        let done = expectation(description: "probe")
        DispatchQueue.global(qos: .userInitiated).async {
            let dem    = makeAlpineProfile()
            let demMin = dem.map { $0.elevationAngleDegrees }.min()!
            let demMax = dem.map { $0.elevationAngleDegrees }.max()!
            var rng    = RNG(seed: 42)
            let vp     = makeVisionProfile(dem: dem, heading: 180, trueOffset: 5,
                                           sigma: 0.25, rng: &rng,
                                           demMin: demMin, demMax: demMax)
            let result = SkylineProfileMatcher.match(visionProfile: vp,
                                                     demSkyline: dem,
                                                     currentHeading: 180)
            XCTAssertNotNil(result, "match() returned nil")
            print("PROBE OK: correction=\(result?.correctionDegrees ?? 0)°  Q=\(result?.quality ?? 0)")
            done.fulfill()
        }
        waitForExpectations(timeout: 60)
    }

    // ── Core experiment logic (background thread) ────────────────────────────

    private func runExperiments(failures: inout [String]) throws {

        let dem    = makeAlpineProfile()
        let demMin = dem.map { $0.elevationAngleDegrees }.min()!
        let demMax = dem.map { $0.elevationAngleDegrees }.max()!
        var rows:  [EvalRow] = []

        print("\n╔═══════════════════════════════════════════════════════════╗")
        print("║  SkylineProfileMatcher Evaluation Harness               ║")
        print("╠═══════════════════════════════════════════════════════════╣")
        print("║  DEM: \(kDEMResLabel.padding(toLength: 47, withPad: " ", startingAt: 0))║")
        print("╚═══════════════════════════════════════════════════════════╝")

        // ─── Experiment A: Heading Recovery ───────────────────────────────────
        print("\n── Exp A: Heading Recovery ──────────────────────────────────────")
        print("  σ(°)    mean(°)   med(°)    p95(°)    accept%")
        print("  " + String(repeating: "─", count: 48))

        for sigma in Self.noises {
            var errs: [Double] = []
            var nAcc = 0
            var rng  = RNG(seed: 42)

            for delta in Self.offsets {
                for _ in 0 ..< Self.trialsA {
                    let vp = makeVisionProfile(
                        dem: dem, heading: Self.H,
                        trueOffset: delta, sigma: sigma,
                        rng: &rng, demMin: demMin, demMax: demMax
                    )
                    guard let r = SkylineProfileMatcher.match(
                        visionProfile:  vp, demSkyline:     dem,
                        currentHeading: Self.H, hFOV:       Self.hFOV
                    ) else { continue }

                    let err = abs(r.correctionDegrees - delta)
                    let ok  = r.quality >= 0.3
                    if ok { nAcc += 1 }
                    errs.append(err)
                    rows.append(EvalRow(
                        experiment: "A", sigma: sigma, trueOffset: delta,
                        occPct: 0,   recovered: r.correctionDegrees,
                        qScore: r.quality, absError: err, accepted: ok
                    ))
                }
            }

            let (mn, med, p95) = stats(errs)
            let acc = Double(nAcc) / Double(max(1, errs.count)) * 100
            print(String(format: "  %-6.2f  %-9.3f  %-9.3f  %-9.3f  %-9.1f",
                         sigma, mn, med, p95, acc))
        }

        // ─── Experiment B: Featureless Rejection ──────────────────────────────
        print("\n── Exp B: Featureless Rejection  (σ = 0.25°) ───────────────────")

        // Flat DEM: range = 0 < 0.5° threshold → normaliseDEM maps every
        // bearing to 0.5 → SSD is constant across all offsets → quality = 0.
        let flatDEM: [SkylinePoint] = (0 ..< kDEMStepCount).map { i in
            SkylinePoint(bearingDegrees:        Double(i) * kDEMStepDeg,
                         elevationAngleDegrees: 0.25,
                         distanceKm:           50.0)
        }
        var rngB = RNG(seed: 42)
        var qsB: [Double] = []
        var nRej = 0

        for _ in 0 ..< Self.trialsB {
            var bearings:   [Double] = []
            var elevations: [Double] = []
            for col in 0 ..< 120 {
                let nx   = (Double(col) + 0.5) / 120.0
                let bOff = (nx - 0.5) * Self.hFOV
                bearings.append((Self.H + bOff + 360).truncatingRemainder(dividingBy: 360))
                elevations.append(max(0, min(1, 0.5 + rngB.gaussian(std: 0.1))))
            }
            let vp = VisionSkylineProfile(bearings: bearings, elevations: elevations)

            if let r = SkylineProfileMatcher.match(
                visionProfile:  vp, demSkyline:     flatDEM,
                currentHeading: Self.H, hFOV:       Self.hFOV
            ) {
                qsB.append(r.quality)
                let ok = r.quality >= 0.3
                if !ok { nRej += 1 }
                rows.append(EvalRow(
                    experiment: "B", sigma: 0.25, trueOffset: 0,
                    occPct: 0,   recovered: r.correctionDegrees,
                    qScore: r.quality, absError: abs(r.correctionDegrees), accepted: ok
                ))
            }
        }

        let rejRate         = Double(nRej) / Double(Self.trialsB) * 100
        let (qMn, qMed, _) = stats(qsB)
        print(String(format: "  Rejection rate : %.1f%%  (target > 90%%)", rejRate))
        print(String(format: "  Q distribution : mean=%.4f  median=%.4f  range=%.4f…%.4f",
                     qMn, qMed, qsB.min() ?? 0, qsB.max() ?? 0))
        if rejRate <= 90.0 {
            failures.append("Exp B: featureless rejection \(rejRate)% ≤ 90% threshold")
        }

        // ─── Experiment C: Occlusion Robustness ───────────────────────────────
        print("\n── Exp C: Occlusion Robustness  (σ=0.25°, δ=10°) ───────────────")
        print("  occlusion%   mean_err(°)  accept%")
        print("  " + String(repeating: "─", count: 36))

        for occ in Self.occFracs {
            var rngC = RNG(seed: 42)
            var errs: [Double] = []
            var nAcc = 0

            for _ in 0 ..< Self.trialsC {
                let vp = makeVisionProfile(
                    dem: dem, heading: Self.H,
                    trueOffset: 10.0, sigma: 0.25,
                    occFraction: occ,
                    rng: &rngC, demMin: demMin, demMax: demMax
                )
                guard let r = SkylineProfileMatcher.match(
                    visionProfile:  vp, demSkyline:     dem,
                    currentHeading: Self.H, hFOV:       Self.hFOV
                ) else { continue }

                let err = abs(r.correctionDegrees - 10.0)
                let ok  = r.quality >= 0.3
                if ok { nAcc += 1 }
                errs.append(err)
                rows.append(EvalRow(
                    experiment: "C", sigma: 0.25, trueOffset: 10.0,
                    occPct: occ * 100, recovered: r.correctionDegrees,
                    qScore: r.quality, absError: err, accepted: ok
                ))
            }

            let mn  = errs.reduce(0, +) / Double(max(1, errs.count))
            let acc = Double(nAcc) / Double(Self.trialsC) * 100
            print(String(format: "  %-12.0f  %-11.3f  %-9.1f", occ * 100, mn, acc))
        }

        // ─── Write CSV ─────────────────────────────────────────────────────────
        let header = "experiment,sigma,true_offset,occlusion_pct,recovered_offset,q_score,abs_error,accepted"
        let csvStr = header + "\n" + rows.map { $0.csv }.joined(separator: "\n")

        let docs   = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let csvURL = docs.appendingPathComponent("evaluation_results.csv")
        try csvStr.write(to: csvURL, atomically: true, encoding: .utf8)

        print("\n✓ CSV → \(csvURL.path)")
        print("  \(rows.count) rows: A=\(rows.filter{$0.experiment=="A"}.count)  B=\(rows.filter{$0.experiment=="B"}.count)  C=\(rows.filter{$0.experiment=="C"}.count)")
        print("  DEM: \(kDEMResLabel)")
    }

    // =========================================================================
    // MARK: – Part 4: Performance Benchmarks
    // =========================================================================

    func testPerformanceBenchmarks() {
        executionTimeAllowance = 3600
        let done = expectation(description: "benchmarks_complete")

        DispatchQueue.global(qos: .userInitiated).async {
            do   { try self.runBenchmarks() }
            catch { XCTFail("Benchmark error: \(error)") }
            done.fulfill()
        }

        waitForExpectations(timeout: 3600)
    }

    private func runBenchmarks() throws {
        let docs   = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let demDir = docs.appendingPathComponent("dem", isDirectory: true)
        try FileManager.default.createDirectory(at: demDir, withIntermediateDirectories: true)

        struct B { let component, notes: String; let medMs: Double }
        var results: [B] = []

        // ── 1. DEMReader: load one SRTM1 tile ──────────────────────────────────
        // "N00E000" = ocean tile at 0°N 0°E — safe to synthesise without
        // conflicting with any downloaded Alpine tile.
        let tileA  = "N00E000"
        let tileAU = demDir.appendingPathComponent("\(tileA).hgt")
        try syntheticHGT(gridSize: 3601, elevation: 900).write(to: tileAU)
        defer { try? FileManager.default.removeItem(at: tileAU) }
        _ = DEMReader.load(tileName: tileA)                          // warm OS cache

        results.append(B(
            component: "DEMReader.load() — SRTM1 3601×3601",
            notes:     "synthetic flat tile (25.9 MB); warm OS cache after 1 preflight",
            medMs:     medianMs { _ = DEMReader.load(tileName: tileA) }
        ))

        // ── 2. DEMSkylineRenderer: full 720-bearing render ─────────────────────
        // Write synthetic SRTM3 tiles (2.9 MB each) for all required names.
        // Existing downloaded tiles are reused and not overwritten.
        let centre    = CLLocationCoordinate2D(latitude: 46.5, longitude: 7.5)
        let tileNames = DEMTileManager.requiredTiles(for: centre, radiusKm: 80)
        let srtm3     = syntheticHGT(gridSize: 1201, elevation: 900)
        var wroteURLs: [URL] = []
        for name in tileNames {
            let u = demDir.appendingPathComponent("\(name).hgt")
            if !FileManager.default.fileExists(atPath: u.path) {
                try srtm3.write(to: u); wroteURLs.append(u)
            }
        }
        defer { wroteURLs.forEach { try? FileManager.default.removeItem(at: $0) } }

        var cache = DEMReaderCache()
        cache.load(tilesFor: centre)
        let userLoc = CLLocation(coordinate: centre, altitude: 2000,
                                 horizontalAccuracy: 1, verticalAccuracy: 1,
                                 timestamp: Date())
        _ = DEMSkylineRenderer.render(from: userLoc, using: cache)  // warm

        let tileNote = "\(tileNames.count) tiles (\(wroteURLs.count) synthetic SRTM3, \(tileNames.count - wroteURLs.count) real); 80 km, 150 m steps"
        results.append(B(
            component: "DEMSkylineRenderer.render() — 720 bearings",
            notes:     tileNote,
            medMs:     medianMs { _ = DEMSkylineRenderer.render(from: userLoc, using: cache) }
        ))

        // ── 3. SkylineProfileMatcher: ±30° SSD search, 720-pt DEM ─────────────
        // Always uses the full 720-pt DEM regardless of simulator mode.
        let dem720  = makeAlpineProfile(stepCount: 720, stepDeg: 0.5)
        let d720Min = dem720.map { $0.elevationAngleDegrees }.min()!
        let d720Max = dem720.map { $0.elevationAngleDegrees }.max()!
        var rng     = RNG(seed: 42)
        let vp      = makeVisionProfile(dem: dem720, heading: 180, trueOffset: 10,
                                        sigma: 0.25, rng: &rng,
                                        demMin: d720Min, demMax: d720Max)
        _ = SkylineProfileMatcher.match(visionProfile: vp, demSkyline: dem720,
                                         currentHeading: 180)            // warm

        results.append(B(
            component: "SkylineProfileMatcher.match() — ±30° / 0.5° step",
            notes:     "121 search steps × 120 samples + 10-sample quality; 720-pt alpine DEM",
            medMs:     medianMs { _ = SkylineProfileMatcher.match(visionProfile: vp,
                                                                    demSkyline: dem720,
                                                                    currentHeading: 180) }
        ))

        // ── 4. Peak memory ──────────────────────────────────────────────────────
        var memNote = "unavailable"
        var info    = mach_task_basic_info()
        var cnt     = mach_msg_type_number_t(
            MemoryLayout<mach_task_basic_info>.size / MemoryLayout<integer_t>.size)
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(cnt)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &cnt)
            }
        }
        if kr == KERN_SUCCESS {
            memNote = String(format: "%.1f MB resident RSS (post-render)", Double(info.resident_size) / 1_048_576)
        }

        // ── Markdown table ──────────────────────────────────────────────────────
        print("\n── Part 4: On-Device Performance Benchmarks ─────────────────────")
        print("")
        print("| Component | Median (ms) | Notes |")
        print("|-----------|:-----------:|-------|")
        for r in results {
            print(String(format: "| %@ | %.2f | %@ |", r.component, r.medMs, r.notes))
        }
        print(String(format: "| Peak memory (skyline render) | — | %@ |", memNote))
        print("")
        print("_Median of 10 runs; one warm-up call excluded._")
        print("_SRTM3 synthetic tiles used for renderer setup; production downloads SRTM1._")
        print("_Performance benchmark always uses the full 720-pt DEM (production config)._")
    }
}
