import Foundation

struct MatchResult {
    /// Bearing correction in degrees to add to current magnetometer heading.
    /// correctedHeading = magnetometerHeading + correction
    let correctionDegrees: Double
    /// Match quality 0–1. Higher = more confident the correction is accurate.
    /// Values below 0.3 should be discarded (profile too flat or too noisy).
    let quality: Double
    /// Whether this result is reliable enough to use
    var isReliable: Bool { quality >= 0.3 }
}

struct SkylineProfileMatcher {

    /// Search window: how far left/right of the current heading to search, in degrees.
    static let searchWindowDegrees = 30.0
    /// Step size for the sliding search, in degrees.
    static let searchStepDegrees = 0.5

    /// Compare a Vision-extracted skyline against a DEM-rendered skyline.
    /// visionProfile: output of VisionSkylineExtractor.extract()
    /// demSkyline: output of DEMSkylineRenderer.render() — full 360° array
    /// currentHeading: current magnetometer heading in degrees (0–360)
    /// hFOV: camera horizontal field of view in degrees
    /// Returns the best-match correction or nil if the profile is not usable.
    static func match(visionProfile: VisionSkylineProfile,
                      demSkyline: [SkylinePoint],
                      currentHeading: Double,
                      hFOV: Double = 60.0) -> MatchResult? {

        guard visionProfile.isUsable, !demSkyline.isEmpty else { return nil }

        // Normalise the DEM skyline elevations to 0–1 range for comparison
        // with the normalised Vision profile elevations
        let demNormalised = normaliseDEM(demSkyline)

        var bestSSD = Double.infinity
        var bestCorrection = 0.0

        // Slide Vision profile across DEM within the search window
        let steps = Int(searchWindowDegrees * 2 / searchStepDegrees)
        for step in 0...steps {
            let offsetDeg = -searchWindowDegrees + Double(step) * searchStepDegrees
            let ssd = computeSSD(visionProfile: visionProfile,
                                  demNormalised: demNormalised,
                                  headingOffset: offsetDeg,
                                  referenceHeading: currentHeading,
                                  hFOV: hFOV)
            if ssd < bestSSD {
                bestSSD = ssd
                bestCorrection = offsetDeg
            }
        }

        // Compute quality: how much better is the best match vs the mean SSD?
        // A flat profile (all SSD values similar) means the skyline is featureless
        // and we can't trust the match.
        let quality = computeQuality(bestSSD: bestSSD,
                                      visionProfile: visionProfile,
                                      demNormalised: demNormalised,
                                      referenceHeading: currentHeading,
                                      hFOV: hFOV,
                                      searchStepDegrees: searchStepDegrees,
                                      searchWindowDegrees: searchWindowDegrees)

        return MatchResult(correctionDegrees: bestCorrection, quality: quality)
    }

    // MARK: - Private

    /// Sample the DEM skyline at a specific absolute bearing using linear interpolation
    /// between the two nearest SkylinePoint entries.
    private static func demElevation(at bearingDeg: Double,
                                      from demNormalised: [(bearing: Double, elevation: Double)]) -> Double? {
        guard !demNormalised.isEmpty else { return nil }

        // Find surrounding entries
        var lower: (bearing: Double, elevation: Double)? = nil
        var upper: (bearing: Double, elevation: Double)? = nil

        for point in demNormalised {
            var delta = point.bearing - bearingDeg
            // Normalise delta to -180…180 for wrap-around handling
            if delta > 180  { delta -= 360 }
            if delta < -180 { delta += 360 }

            if delta <= 0 {
                if lower == nil || delta > (lower!.bearing - bearingDeg) {
                    lower = point
                }
            } else {
                if upper == nil || delta < (upper!.bearing - bearingDeg) {
                    upper = point
                }
            }
        }

        guard let lo = lower, let hi = upper else {
            return lower?.elevation ?? upper?.elevation
        }

        // Linear interpolation between lo and hi
        var span = hi.bearing - lo.bearing
        if span < 0 { span += 360 }
        guard span > 0 else { return lo.elevation }

        var t = bearingDeg - lo.bearing
        if t < 0 { t += 360 }
        t /= span

        return lo.elevation * (1 - t) + hi.elevation * t
    }

    /// Compute SSD between Vision profile and DEM profile at a given heading offset.
    private static func computeSSD(visionProfile: VisionSkylineProfile,
                                    demNormalised: [(bearing: Double, elevation: Double)],
                                    headingOffset: Double,
                                    referenceHeading: Double,
                                    hFOV: Double) -> Double {
        var sumSq = 0.0
        var count = 0

        for i in 0..<visionProfile.count {
            // Shift the Vision profile's bearing by the test offset
            var shiftedBearing = visionProfile.bearings[i] + headingOffset
            shiftedBearing = (shiftedBearing + 360).truncatingRemainder(dividingBy: 360)

            guard let demElev = demElevation(at: shiftedBearing, from: demNormalised) else { continue }

            let diff = visionProfile.elevations[i] - demElev
            sumSq += diff * diff
            count += 1
        }

        return count > 0 ? sumSq / Double(count) : Double.infinity
    }

    /// Normalise DEM skyline elevation angles to 0–1 range.
    /// Maps the full elevation angle range present in the DEM slice to [0, 1].
    private static func normaliseDEM(_ skyline: [SkylinePoint]) -> [(bearing: Double, elevation: Double)] {
        guard !skyline.isEmpty else { return [] }
        let elevations = skyline.map { $0.elevationAngleDegrees }
        let minE = elevations.min() ?? 0
        let maxE = elevations.max() ?? 1
        let range = maxE - minE
        guard range > 0.5 else {
            // Profile is too flat — normalise to 0.5 (featureless)
            return skyline.map { ($0.bearingDegrees, 0.5) }
        }
        return skyline.map { point in
            let norm = (point.elevationAngleDegrees - minE) / range
            return (point.bearingDegrees, norm)
        }
    }

    /// Compute a quality score based on how distinct the best match is
    /// versus the average match across the search window.
    private static func computeQuality(bestSSD: Double,
                                        visionProfile: VisionSkylineProfile,
                                        demNormalised: [(bearing: Double, elevation: Double)],
                                        referenceHeading: Double,
                                        hFOV: Double,
                                        searchStepDegrees: Double,
                                        searchWindowDegrees: Double) -> Double {
        // Sample a spread of SSD values across the search window
        var ssdSamples: [Double] = []
        let sampleCount = 10
        for i in 0..<sampleCount {
            let offset = -searchWindowDegrees + Double(i) * (searchWindowDegrees * 2 / Double(sampleCount))
            let ssd = computeSSD(visionProfile: visionProfile,
                                  demNormalised: demNormalised,
                                  headingOffset: offset,
                                  referenceHeading: referenceHeading,
                                  hFOV: hFOV)
            ssdSamples.append(ssd)
        }

        let meanSSD = ssdSamples.reduce(0, +) / Double(ssdSamples.count)
        guard meanSSD > 0 else { return 0 }

        // Quality = how much better the best match is vs the mean
        // If bestSSD ≈ meanSSD, the profile is flat and the match is unreliable (quality → 0)
        // If bestSSD << meanSSD, the match is distinctive (quality → 1)
        let ratio = bestSSD / meanSSD
        let quality = max(0, min(1, 1.0 - ratio))
        return quality
    }
}
