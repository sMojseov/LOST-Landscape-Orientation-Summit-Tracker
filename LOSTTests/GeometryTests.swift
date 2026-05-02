import XCTest
import CoreLocation
@testable import LOST

final class GeometryTests: XCTestCase {

    // MARK: - calculateAzimuth: Cardinal directions

    func testAzimuthDueNorth() {
        // Moving north along the same meridian should give 0°
        let from = CLLocationCoordinate2D(latitude: 46.0, longitude: 8.0)
        let to   = CLLocationCoordinate2D(latitude: 47.0, longitude: 8.0)
        let bearing = PeakFinderService.calculateAzimuth(from: from, to: to)
        XCTAssertEqual(bearing, 0.0, accuracy: 0.5,
                       "Due north should be 0° (or 360°), got \(bearing)°")
    }

    func testAzimuthDueSouth() {
        let from = CLLocationCoordinate2D(latitude: 47.0, longitude: 8.0)
        let to   = CLLocationCoordinate2D(latitude: 46.0, longitude: 8.0)
        let bearing = PeakFinderService.calculateAzimuth(from: from, to: to)
        XCTAssertEqual(bearing, 180.0, accuracy: 0.5,
                       "Due south should be 180°, got \(bearing)°")
    }

    func testAzimuthDueEast() {
        let from = CLLocationCoordinate2D(latitude: 46.0, longitude: 8.0)
        let to   = CLLocationCoordinate2D(latitude: 46.0, longitude: 9.0)
        let bearing = PeakFinderService.calculateAzimuth(from: from, to: to)
        XCTAssertEqual(bearing, 90.0, accuracy: 1.5,
                       "Due east should be ~90°, got \(bearing)°")
        // Note: ±1.5° tolerance because moving along a latitude line is not
        // exactly east at non-equatorial latitudes due to spherical geometry.
    }

    func testAzimuthDueWest() {
        let from = CLLocationCoordinate2D(latitude: 46.0, longitude: 9.0)
        let to   = CLLocationCoordinate2D(latitude: 46.0, longitude: 8.0)
        let bearing = PeakFinderService.calculateAzimuth(from: from, to: to)
        XCTAssertEqual(bearing, 270.0, accuracy: 1.5,
                       "Due west should be ~270°, got \(bearing)°")
    }

    // MARK: - calculateAzimuth: Output range

    func testAzimuthAlwaysInRange0To360() {
        // Test a grid of coordinate pairs — azimuth must always be 0...360
        let origins: [CLLocationCoordinate2D] = [
            CLLocationCoordinate2D(latitude: 46.0, longitude: 8.0),
            CLLocationCoordinate2D(latitude: -33.9, longitude: 151.2),
            CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0),
            CLLocationCoordinate2D(latitude: 89.0, longitude: 0.0)
        ]
        let destinations: [CLLocationCoordinate2D] = [
            CLLocationCoordinate2D(latitude: 47.0, longitude: 7.0),
            CLLocationCoordinate2D(latitude: -34.5, longitude: 150.0),
            CLLocationCoordinate2D(latitude: -1.0, longitude: 1.0),
            CLLocationCoordinate2D(latitude: 88.0, longitude: 180.0)
        ]
        for (from, to) in zip(origins, destinations) {
            let bearing = PeakFinderService.calculateAzimuth(from: from, to: to)
            XCTAssertGreaterThanOrEqual(bearing, 0.0,
                "Bearing should be >= 0°, got \(bearing)° for \(from) → \(to)")
            XCTAssertLessThan(bearing, 360.0,
                "Bearing should be < 360°, got \(bearing)° for \(from) → \(to)")
        }
    }

    // MARK: - calculateAzimuth: Known Alpine reference pairs

    func testAzimuthZermattToMatterhorn() {
        // Zermatt village → Matterhorn summit
        // Matterhorn is southwest of Zermatt village (computed: ~235°, SW/WSW)
        // Expected: roughly 220–250° (SW to WSW)
        let zermatt     = CLLocationCoordinate2D(latitude: 46.0207, longitude: 7.7491)
        let matterhorn  = CLLocationCoordinate2D(latitude: 45.9765, longitude: 7.6585)
        let bearing = PeakFinderService.calculateAzimuth(from: zermatt, to: matterhorn)
        XCTAssertGreaterThan(bearing, 220.0,
            "Zermatt→Matterhorn should be SW/WSW (>220°), got \(bearing)°")
        XCTAssertLessThan(bearing, 250.0,
            "Zermatt→Matterhorn should be SW/WSW (<250°), got \(bearing)°")
    }

    func testAzimuthGarmischToZugspitze() {
        // Garmisch-Partenkirchen → Zugspitze
        // Zugspitze is southwest of Garmisch
        // Expected: roughly 220–250° (SW)
        let garmisch  = CLLocationCoordinate2D(latitude: 47.4928, longitude: 11.0958)
        let zugspitze = CLLocationCoordinate2D(latitude: 47.4211, longitude: 10.9848)
        let bearing = PeakFinderService.calculateAzimuth(from: garmisch, to: zugspitze)
        XCTAssertGreaterThan(bearing, 215.0,
            "Garmisch→Zugspitze should be SW (>215°), got \(bearing)°")
        XCTAssertLessThan(bearing, 255.0,
            "Garmisch→Zugspitze should be SW (<255°), got \(bearing)°")
    }

    // MARK: - Azimuth delta normalisation (the wrapping fix)

    func testDeltaNormalisationNearZeroBoundary() {
        // Peak at 5°, heading 355° → should be +10°, NOT -350°
        let delta = azimuthDelta(peakAzimuth: 5.0, heading: 355.0)
        XCTAssertEqual(delta, 10.0, accuracy: 0.001,
            "Peak at 5°, heading 355° → delta should be +10°, got \(delta)°")
    }

    func testDeltaNormalisationNear360Boundary() {
        // Peak at 355°, heading 5° → should be -10°, NOT +350°
        let delta = azimuthDelta(peakAzimuth: 355.0, heading: 5.0)
        XCTAssertEqual(delta, -10.0, accuracy: 0.001,
            "Peak at 355°, heading 5° → delta should be -10°, got \(delta)°")
    }

    func testDeltaNormalisationDirectlyAhead() {
        // Peak at exactly the heading → delta should be 0°
        let delta = azimuthDelta(peakAzimuth: 247.0, heading: 247.0)
        XCTAssertEqual(delta, 0.0, accuracy: 0.001,
            "Peak directly ahead → delta should be 0°, got \(delta)°")
    }

    func testDeltaNormalisationDirectlyBehind() {
        // Peak 180° behind → delta should be ±180°
        let delta = azimuthDelta(peakAzimuth: 90.0, heading: 270.0)
        XCTAssertEqual(abs(delta), 180.0, accuracy: 0.001,
            "Peak directly behind → |delta| should be 180°, got \(delta)°")
    }

    func testDeltaNormalisationAlwaysInMinus180To180() {
        // For any heading/peak combination, delta must be in -180...180
        let headings = stride(from: 0.0, to: 360.0, by: 15.0)
        let azimuths = stride(from: 0.0, to: 360.0, by: 15.0)
        for h in headings {
            for a in azimuths {
                let delta = azimuthDelta(peakAzimuth: a, heading: h)
                XCTAssertGreaterThanOrEqual(delta, -180.0,
                    "Delta should be >= -180°, got \(delta)° for azimuth=\(a)° heading=\(h)°")
                XCTAssertLessThanOrEqual(delta, 180.0,
                    "Delta should be <= 180°, got \(delta)° for azimuth=\(a)° heading=\(h)°")
            }
        }
    }

    func testDeltaFilterWindow45Degrees() {
        // Peaks within ±45° of heading should pass the filter
        // Peaks outside ±45° should be filtered out
        let heading = 90.0
        let insideLeft   = azimuthDelta(peakAzimuth: 46.0,  heading: heading)  // -44° → inside
        let insideRight  = azimuthDelta(peakAzimuth: 134.0, heading: heading)  // +44° → inside
        let outsideLeft  = azimuthDelta(peakAzimuth: 44.0,  heading: heading)  // -46° → outside
        let outsideRight = azimuthDelta(peakAzimuth: 136.0, heading: heading)  // +46° → outside

        XCTAssertTrue(abs(insideLeft)  < 45, "Peak at 46° with heading 90° should be inside ±45°")
        XCTAssertTrue(abs(insideRight) < 45, "Peak at 134° with heading 90° should be inside ±45°")
        XCTAssertFalse(abs(outsideLeft)  < 45, "Peak at 44° with heading 90° should be outside ±45°")
        XCTAssertFalse(abs(outsideRight) < 45, "Peak at 136° with heading 90° should be outside ±45°")
    }

    // MARK: - Elevation angle with Earth curvature correction

    func testElevationAngleFlatSameAltitude() {
        // Same altitude, any distance → angle should be ≈ 0° (slightly negative due to curvature)
        let angle = elevationAngle(altDiffMetres: 0, distanceMetres: 10_000)
        XCTAssertEqual(angle, 0.0, accuracy: 0.5,
            "Same altitude 10km away → ~0°, got \(angle)°")
    }

    func testElevationAngleUphillShort() {
        // 100m above, 1000m away → atan(100/1000) ≈ 5.71°
        // Curvature correction at 1km: 1000² / (2 * 6371000) ≈ 0.08m — negligible
        let angle = elevationAngle(altDiffMetres: 100, distanceMetres: 1_000)
        XCTAssertEqual(angle, 5.71, accuracy: 0.15,
            "100m above at 1km → ~5.71°, got \(angle)°")
    }

    func testElevationAngleDownhillShort() {
        // 200m below, 2000m away → negative angle
        let angle = elevationAngle(altDiffMetres: -200, distanceMetres: 2_000)
        XCTAssertLessThan(angle, 0.0,
            "Peak below horizon should give negative elevation angle, got \(angle)°")
        XCTAssertEqual(angle, -5.71, accuracy: 0.5,
            "200m below at 2km → ~-5.71°, got \(angle)°")
    }

    func testElevationAngleCurvatureCorrectionAt80km() {
        // At 80km, curvature correction ≈ 503m
        // A peak at exactly 503m above the user at 80km → correctedDiff ≈ 0 → angle ≈ 0°
        let d = 80_000.0
        let curvature = (d * d) / (2.0 * 6_371_000.0)   // ≈ 503m
        let angle = elevationAngle(altDiffMetres: curvature, distanceMetres: d)
        XCTAssertEqual(angle, 0.0, accuracy: 0.3,
            "Peak at geodetic horizon (alt=curvature) → ~0°, got \(angle)°")
    }

    func testElevationAngleMatterhornFromZermatt() {
        // From Zermatt (1620m) to Matterhorn (4478m), distance ≈ 9.5km
        // altDiff ≈ 2858m, distance ≈ 9500m
        // Expected elevation angle: roughly 15–20° above horizontal
        let angle = elevationAngle(altDiffMetres: 2858, distanceMetres: 9_500)
        XCTAssertGreaterThan(angle, 14.0,
            "Matterhorn from Zermatt should be >14° above horizon, got \(angle)°")
        XCTAssertLessThan(angle, 22.0,
            "Matterhorn from Zermatt should be <22° above horizon, got \(angle)°")
    }

    func testElevationAngleNeverExceeds90() {
        // Pathological input: peak directly above
        let angle = elevationAngle(altDiffMetres: 10_000, distanceMetres: 1)
        XCTAssertLessThanOrEqual(angle, 90.0,
            "Elevation angle should never exceed 90°, got \(angle)°")
    }

    // MARK: - findVisiblePeaks integration

    func testFindVisiblePeaksReturnsNonEmpty() {
        // From Zermatt, with 100km radius, should find multiple Alpine peaks
        let zermatt = CLLocation(latitude: 46.0207, longitude: 7.7491)
        let peaks = PeakFinderService.findVisiblePeaks(
            userLocation: zermatt,
            mountains: Mountain.data,
            maxDistance: 100_000
        )
        XCTAssertFalse(peaks.isEmpty,
            "Should find peaks within 100km of Zermatt")
    }

    func testFindVisiblePeaksDistanceIsInMetres() {
        // All returned distances should be in metres (< 100,000) not km (< 100)
        let zermatt = CLLocation(latitude: 46.0207, longitude: 7.7491)
        let peaks = PeakFinderService.findVisiblePeaks(
            userLocation: zermatt,
            mountains: Mountain.data,
            maxDistance: 100_000
        )
        for peak in peaks {
            XCTAssertGreaterThan(peak.distance, 100,
                "\(peak.mountain.name) distance should be in metres (>100m), got \(peak.distance)")
            XCTAssertLessThanOrEqual(peak.distance, 100_000,
                "\(peak.mountain.name) distance exceeds maxDistance: \(peak.distance)m")
        }
    }

    func testFindVisiblePeaksAzimuthInRange() {
        // All azimuth values must be 0–360
        let location = CLLocation(latitude: 47.0, longitude: 10.0)
        let peaks = PeakFinderService.findVisiblePeaks(
            userLocation: location,
            mountains: Mountain.data,
            maxDistance: 200_000
        )
        for peak in peaks {
            XCTAssertGreaterThanOrEqual(peak.azimuth, 0.0,
                "\(peak.mountain.name) azimuth < 0: \(peak.azimuth)°")
            XCTAssertLessThan(peak.azimuth, 360.0,
                "\(peak.mountain.name) azimuth >= 360: \(peak.azimuth)°")
        }
    }

    func testFindVisiblePeaksMaxDistanceRespected() {
        // With maxDistance 10km from Zermatt, should find far fewer peaks than 100km
        let zermatt = CLLocation(latitude: 46.0207, longitude: 7.7491)
        let nearPeaks = PeakFinderService.findVisiblePeaks(
            userLocation: zermatt,
            mountains: Mountain.data,
            maxDistance: 10_000
        )
        let farPeaks = PeakFinderService.findVisiblePeaks(
            userLocation: zermatt,
            mountains: Mountain.data,
            maxDistance: 100_000
        )
        XCTAssertLessThan(nearPeaks.count, farPeaks.count,
            "10km radius should return fewer peaks than 100km radius")
    }

    func testMatterhornFoundFromZermatt() {
        // Matterhorn must appear in results when searching from Zermatt
        let zermatt = CLLocation(latitude: 46.0207, longitude: 7.7491)
        let peaks = PeakFinderService.findVisiblePeaks(
            userLocation: zermatt,
            mountains: Mountain.data,
            maxDistance: 50_000
        )
        let matterhorn = peaks.first { $0.mountain.name == "Matterhorn" }
        XCTAssertNotNil(matterhorn, "Matterhorn should be visible from Zermatt within 50km")

        if let m = matterhorn {
            // Matterhorn is ~12-14km from Zermatt village
            XCTAssertGreaterThan(m.distance, 8_000,
                "Matterhorn distance from Zermatt should be >8km, got \(m.distance / 1000)km")
            XCTAssertLessThan(m.distance, 18_000,
                "Matterhorn distance from Zermatt should be <18km, got \(m.distance / 1000)km")
            // Matterhorn is SW/WSW of Zermatt (computed bearing ~235°)
            XCTAssertGreaterThan(m.azimuth, 220,
                "Matterhorn azimuth from Zermatt should be >220°, got \(m.azimuth)°")
            XCTAssertLessThan(m.azimuth, 250,
                "Matterhorn azimuth from Zermatt should be <250°, got \(m.azimuth)°")
            // Matterhorn is well above Zermatt village (1620m → 4478m)
            XCTAssertGreaterThan(m.elevationAngle, 10.0,
                "Matterhorn elevation angle from Zermatt should be >10°, got \(m.elevationAngle)°")
        }
    }

    // MARK: - Helpers (private test utilities)

    /// The normalised azimuth delta formula from ScanningViewModel.updatePeaksAndConfidence()
    private func azimuthDelta(peakAzimuth: Double, heading: Double) -> Double {
        return (peakAzimuth - heading + 540)
            .truncatingRemainder(dividingBy: 360) - 180
    }

    /// Elevation angle with Earth curvature correction
    /// Matches the formula used in DEMSkylineRenderer and PeakFinderService
    private func elevationAngle(altDiffMetres: Double, distanceMetres: Double) -> Double {
        let R = 6_371_000.0
        let curvatureCorrection = (distanceMetres * distanceMetres) / (2.0 * R)
        let correctedDiff = altDiffMetres - curvatureCorrection
        return atan2(correctedDiff, distanceMetres) * 180.0 / .pi
    }
}
