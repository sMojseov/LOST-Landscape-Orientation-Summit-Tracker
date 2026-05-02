//
//  DEMReader.swift
//  LOST
//

import Foundation
import CoreLocation

struct DEMReader {

    private let data: Data
    private let tileLat: Int
    private let tileLon: Int
    private let gridSize: Int
    private var samples: Int { gridSize - 1 }

    static func load(tileName: String) -> DEMReader? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = docs.appendingPathComponent("dem/\(tileName).hgt")
        guard let data = try? Data(contentsOf: fileURL) else { return nil }

        let detectedGrid: Int
        if data.count == 3601 * 3601 * 2 {
            detectedGrid = 3601
        } else if data.count == 1201 * 1201 * 2 {
            detectedGrid = 1201
        } else {
            return nil
        }

        let name = tileName
        guard name.count >= 7 else { return nil }
        let latDir: Double = name.hasPrefix("N") ? 1 : -1
        guard let lonSeparatorIndex = name.firstIndex(of: "E") ?? name.firstIndex(of: "W") else { return nil }
        let lonDir: Double = name[lonSeparatorIndex] == "E" ? 1 : -1
        let latStr = String(name.dropFirst().prefix(2))
        let lonStr = String(name[name.index(after: lonSeparatorIndex)...])
        guard let latVal = Int(latStr), let lonVal = Int(lonStr) else { return nil }

        return DEMReader(
            data: data,
            tileLat: Int(latDir * Double(latVal)),
            tileLon: Int(lonDir * Double(lonVal)),
            gridSize: detectedGrid
        )
    }

    private func rawElevation(row: Int, col: Int) -> Int16? {
        let clampedRow = max(0, min(gridSize - 1, row))
        let clampedCol = max(0, min(gridSize - 1, col))
        let index = (clampedRow * gridSize + clampedCol) * 2
        let raw = data.withUnsafeBytes { ptr in
            ptr.loadUnaligned(fromByteOffset: index, as: Int16.self)
        }
        let elevation = Int16(bigEndian: raw)
        return elevation == -32768 ? nil : elevation
    }

    func elevation(at coordinate: CLLocationCoordinate2D) -> Double? {
        let localLat = coordinate.latitude - Double(tileLat)
        let localLon = coordinate.longitude - Double(tileLon)

        guard localLat >= 0, localLat <= 1, localLon >= 0, localLon <= 1 else { return nil }

        let s = Double(samples)
        let fracRow = (1.0 - localLat) * s
        let fracCol = localLon * s

        let row0 = Int(fracRow)
        let col0 = Int(fracCol)
        let row1 = min(row0 + 1, gridSize - 1)
        let col1 = min(col0 + 1, gridSize - 1)

        let dr = fracRow - Double(row0)
        let dc = fracCol - Double(col0)

        let e00 = Double(rawElevation(row: row0, col: col0) ?? 0)
        let e01 = Double(rawElevation(row: row0, col: col1) ?? 0)
        let e10 = Double(rawElevation(row: row1, col: col0) ?? 0)
        let e11 = Double(rawElevation(row: row1, col: col1) ?? 0)

        let elevation = e00 * (1 - dr) * (1 - dc)
                      + e01 * (1 - dr) * dc
                      + e10 * dr * (1 - dc)
                      + e11 * dr * dc

        return elevation
    }

    func covers(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        return lat >= Double(tileLat) && lat < Double(tileLat + 1) &&
               lon >= Double(tileLon) && lon < Double(tileLon + 1)
    }
}

// MARK: - Multi-tile reader

struct DEMReaderCache {

    private var readers: [String: DEMReader] = [:]

    mutating func load(tilesFor coordinate: CLLocationCoordinate2D) {
        let tileNames = DEMTileManager.requiredTiles(for: coordinate, radiusKm: 80)
        for name in tileNames where readers[name] == nil {
            if let reader = DEMReader.load(tileName: name) {
                readers[name] = reader
            }
        }
    }

    func elevation(at coordinate: CLLocationCoordinate2D) -> Double? {
        for reader in readers.values {
            if reader.covers(coordinate) {
                return reader.elevation(at: coordinate)
            }
        }
        return nil
    }
}
