import Foundation
import CoreGraphics

struct VisionSkylineProfile {
    /// Bearing angles in degrees (absolute, 0–360) for each sample
    let bearings: [Double]
    /// Normalised elevation values 0–1 (0 = horizon level, 1 = top of frame)
    /// Higher value means the skyline is higher in the frame at that bearing
    let elevations: [Double]
    /// Number of valid samples extracted
    var count: Int { bearings.count }
    /// Whether the profile has enough data to be useful for matching
    var isUsable: Bool { count >= 20 }
}

struct VisionSkylineExtractor {

    /// Number of horizontal columns to sample across the frame width
    static let columnCount = 120

    /// Extract the upper envelope of all contour paths.
    /// contourPaths: normalised 0–1 screen-space points (Y=0 is top of frame).
    /// heading: current device bearing in degrees (0–360).
    /// hFOV: horizontal field of view in degrees.
    /// Returns a VisionSkylineProfile mapping bearings to normalised elevations.
    static func extract(from contourPaths: [[CGPoint]],
                        heading: Double,
                        hFOV: Double = 60.0) -> VisionSkylineProfile {

        guard !contourPaths.isEmpty else {
            return VisionSkylineProfile(bearings: [], elevations: [])
        }

        // Build a per-column upper envelope: lowest Y value (highest on screen) at each column
        // Columns span the full frame width 0.0...1.0
        var columnMinY = [Double](repeating: Double.infinity, count: columnCount)

        for path in contourPaths {
            for point in path {
                let col = min(columnCount - 1, Int(point.x * Double(columnCount)))
                if col >= 0 && Double(point.y) < columnMinY[col] {
                    columnMinY[col] = Double(point.y)
                }
            }
        }

        // Fill gaps using linear interpolation between valid columns
        // A column is invalid if no contour point landed in it (still Double.infinity)
        columnMinY = fillGaps(columnMinY)

        // Convert filled columns to bearing + elevation pairs
        var bearings: [Double] = []
        var elevations: [Double] = []

        for col in 0..<columnCount {
            let minY = columnMinY[col]
            guard minY < Double.infinity else { continue }

            // Map column index to bearing offset from heading centre
            // col=0 → left edge (-hFOV/2), col=columnCount-1 → right edge (+hFOV/2)
            let normalizedX = (Double(col) + 0.5) / Double(columnCount)
            let bearingOffset = (normalizedX - 0.5) * hFOV
            var absoluteBearing = heading + bearingOffset
            // Normalise to 0–360
            absoluteBearing = (absoluteBearing + 360).truncatingRemainder(dividingBy: 360)

            // minY is in screen space (0=top, 1=bottom)
            // Convert to normalised elevation (0=horizon, 1=top of frame)
            // We only care about the upper half of the frame for skyline (minY < 0.5 typically)
            // Clamp to 0–1 range and invert: lower Y = higher elevation value
            let normalizedElevation = max(0, min(1, 1.0 - minY))

            bearings.append(absoluteBearing)
            elevations.append(normalizedElevation)
        }

        return VisionSkylineProfile(bearings: bearings, elevations: elevations)
    }

    // MARK: - Private

    /// Fill gaps (Double.infinity values) in the column array using
    /// linear interpolation between adjacent valid values.
    private static func fillGaps(_ input: [Double]) -> [Double] {
        var result = input
        var lastValid: (index: Int, value: Double)? = nil

        // Forward pass: fill from left
        for i in 0..<result.count {
            if result[i] < Double.infinity {
                lastValid = (i, result[i])
            } else if let lv = lastValid {
                result[i] = lv.value  // carry forward
            }
        }

        // Backward pass: fill remaining gaps from right
        lastValid = nil
        for i in stride(from: result.count - 1, through: 0, by: -1) {
            if result[i] < Double.infinity {
                lastValid = (i, result[i])
            } else if let lv = lastValid {
                result[i] = lv.value  // carry backward
            }
        }

        return result
    }
}
