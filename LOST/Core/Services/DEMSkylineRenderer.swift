//
//  DEMSkylineRenderer.swift
//  LOST
//

import Foundation
import CoreLocation

struct SkylinePoint {
    let bearingDegrees: Double
    let elevationAngleDegrees: Double
    let distanceKm: Double
}

struct DEMSkylineRenderer {

    static let stepCount = 720
    static let stepDegrees = 360.0 / Double(stepCount)
    static let maxRangeKm = 80.0
    static let sampleIntervalMetres = 150.0
    private static let earthRadius = 6_371_000.0

    static func render(from userLocation: CLLocation,
                       using demCache: DEMReaderCache) -> [SkylinePoint] {

        let userLat = userLocation.coordinate.latitude
        let userLon = userLocation.coordinate.longitude
        let userAlt = userLocation.altitude

        var skyline: [SkylinePoint] = []
        skyline.reserveCapacity(stepCount)

        for step in 0..<stepCount {
            let bearingDeg = Double(step) * stepDegrees
            let bearingRad = bearingDeg * .pi / 180.0

            var maxElevAngle = -90.0
            var maxElevDistanceKm = 0.0

            let totalSamples = Int(maxRangeKm * 1000.0 / sampleIntervalMetres)

            for sample in 1...totalSamples {
                let distanceMetres = Double(sample) * sampleIntervalMetres
                let distanceKm = distanceMetres / 1000.0

                let sampleCoord = coordinate(from: CLLocationCoordinate2D(latitude: userLat, longitude: userLon),
                                             distanceMetres: distanceMetres,
                                             bearingRadians: bearingRad)

                guard let sampleElevation = demCache.elevation(at: sampleCoord) else { continue }

                let altDiff = sampleElevation - userAlt
                let curveCorrection = (distanceMetres * distanceMetres) / (2.0 * earthRadius)
                let correctedDiff = altDiff - curveCorrection

                let elevAngleRad = atan2(correctedDiff, distanceMetres)
                let elevAngleDeg = elevAngleRad * 180.0 / .pi

                if elevAngleDeg > maxElevAngle {
                    maxElevAngle = elevAngleDeg
                    maxElevDistanceKm = distanceKm
                }
            }

            skyline.append(SkylinePoint(
                bearingDegrees: bearingDeg,
                elevationAngleDegrees: maxElevAngle,
                distanceKm: maxElevDistanceKm
            ))
        }

        return skyline
    }

    static func slice(from skyline: [SkylinePoint],
                      heading: Double,
                      hFOV: Double = 60.0) -> [SkylinePoint] {
        guard !skyline.isEmpty else { return [] }
        return skyline.filter { point in
            var delta = point.bearingDegrees - heading
            if delta > 180  { delta -= 360 }
            if delta < -180 { delta += 360 }
            return abs(delta) <= hFOV / 2.0
        }
    }

    // MARK: - Coordinate math

    private static func coordinate(from origin: CLLocationCoordinate2D,
                                    distanceMetres: Double,
                                    bearingRadians: Double) -> CLLocationCoordinate2D {
        let R = earthRadius
        let lat1 = origin.latitude * .pi / 180
        let lon1 = origin.longitude * .pi / 180
        let d = distanceMetres / R

        let lat2 = asin(sin(lat1) * cos(d) + cos(lat1) * sin(d) * cos(bearingRadians))
        let lon2 = lon1 + atan2(sin(bearingRadians) * sin(d) * cos(lat1),
                                cos(d) - sin(lat1) * sin(lat2))

        return CLLocationCoordinate2D(latitude: lat2 * 180 / .pi,
                                      longitude: lon2 * 180 / .pi)
    }
}
