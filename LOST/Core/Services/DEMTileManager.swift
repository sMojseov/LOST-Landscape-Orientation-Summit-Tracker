//
//  DEMTileManager.swift
//  LOST
//

import Foundation
import CoreLocation
import zlib

actor DEMTileManager {

    static let shared = DEMTileManager()
    private let baseURL = "https://elevation-tiles-prod.s3.amazonaws.com/skadi"
    private let demDirectory: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        demDirectory = docs.appendingPathComponent("dem", isDirectory: true)
        try? FileManager.default.createDirectory(at: demDirectory, withIntermediateDirectories: true)
    }

    static func tileName(for coordinate: CLLocationCoordinate2D) -> String {
        let lat = Int(floor(coordinate.latitude))
        let lon = Int(floor(coordinate.longitude))
        let latDir = lat >= 0 ? "N" : "S"
        let lonDir = lon >= 0 ? "E" : "W"
        return String(format: "%@%02d%@%03d", latDir, abs(lat), lonDir, abs(lon))
    }

    static func requiredTiles(for coordinate: CLLocationCoordinate2D, radiusKm: Double = 80) -> [String] {
        let latDelta = radiusKm / 111.0
        let lonDelta = radiusKm / (111.0 * cos(coordinate.latitude * .pi / 180))

        var tiles: [String] = []
        let latMin = Int(floor(coordinate.latitude - latDelta))
        let latMax = Int(floor(coordinate.latitude + latDelta))
        let lonMin = Int(floor(coordinate.longitude - lonDelta))
        let lonMax = Int(floor(coordinate.longitude + lonDelta))

        for lat in latMin...latMax {
            for lon in lonMin...lonMax {
                let coord = CLLocationCoordinate2D(latitude: Double(lat) + 0.5, longitude: Double(lon) + 0.5)
                tiles.append(tileName(for: coord))
            }
        }
        return tiles
    }

    func isTileDownloaded(_ tileName: String) -> Bool {
        let fileURL = demDirectory.appendingPathComponent("\(tileName).hgt")
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    func areAllTilesDownloaded(for coordinate: CLLocationCoordinate2D) -> Bool {
        let required = DEMTileManager.requiredTiles(for: coordinate)
        return required.allSatisfy { isTileDownloaded($0) }
    }

    func downloadTile(_ tileName: String, progress: @escaping (Double) -> Void) async -> Bool {
        let fileURL = demDirectory.appendingPathComponent("\(tileName).hgt")
        guard !FileManager.default.fileExists(atPath: fileURL.path) else {
            progress(1.0)
            return true
        }

        let latDir = String(tileName.prefix(1))
        let latStr = String(tileName.dropFirst().prefix(2))
        guard let _ = Int(latStr) else { return false }
        let urlString = "\(baseURL)/\(latDir)\(latStr)/\(tileName).hgt.gz"

        guard let url = URL(string: urlString) else { return false }

        do {
            progress(0.1)
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return false }
            progress(0.7)

            guard let decompressed = gunzip(data) else { return false }
            progress(0.9)

            let srtm1 = 3601 * 3601 * 2
            let srtm3 = 1201 * 1201 * 2
            guard decompressed.count == srtm1 || decompressed.count == srtm3 else { return false }

            try decompressed.write(to: fileURL)
            progress(1.0)
            return true
        } catch {
            return false
        }
    }

    func downloadTiles(for coordinate: CLLocationCoordinate2D,
                       progressHandler: @escaping (Double) -> Void) async -> Bool {
        let tiles = DEMTileManager.requiredTiles(for: coordinate)
        let needed = tiles.filter { !isTileDownloaded($0) }

        guard !needed.isEmpty else {
            progressHandler(1.0)
            return true
        }

        var completed = 0
        var allSucceeded = true

        for tileName in needed {
            let success = await downloadTile(tileName) { tileProgress in
                let overall = (Double(completed) + tileProgress) / Double(needed.count)
                progressHandler(overall)
            }
            if !success { allSucceeded = false }
            completed += 1
        }

        progressHandler(1.0)
        return allSucceeded
    }

    func deleteAllTiles() throws {
        let files = try FileManager.default.contentsOfDirectory(at: demDirectory,
                                                                 includingPropertiesForKeys: nil)
        for file in files where file.pathExtension == "hgt" {
            try FileManager.default.removeItem(at: file)
        }
    }

    func downloadedSizeBytes() -> Int64 {
        guard let files = try? FileManager.default.contentsOfDirectory(at: demDirectory,
                                                                        includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        return files.filter { $0.pathExtension == "hgt" }.reduce(0) { sum, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return sum + Int64(size)
        }
    }

    // MARK: - Gzip decompression via zlib

    private func gunzip(_ data: Data) -> Data? {
        var stream = z_stream()
        var result = Data()

        let inputData = data as NSData
        stream.next_in = UnsafeMutablePointer<Bytef>(mutating: inputData.bytes.assumingMemoryBound(to: Bytef.self))
        stream.avail_in = uInt(data.count)

        guard inflateInit2_(&stream, 47, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size)) == Z_OK else {
            return nil
        }
        defer { inflateEnd(&stream) }

        let bufferSize = 65536
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        repeat {
            stream.next_out = buffer
            stream.avail_out = uInt(bufferSize)
            let status = inflate(&stream, Z_NO_FLUSH)
            guard status == Z_OK || status == Z_STREAM_END else { return nil }
            let bytesInflated = bufferSize - Int(stream.avail_out)
            result.append(buffer, count: bytesInflated)
        } while stream.avail_out == 0

        return result.isEmpty ? nil : result
    }
}
