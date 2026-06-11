//
//  DEMReaderTests.swift
//  LOSTTests
//

import Testing
import CoreLocation
@testable import LOST

struct DEMReaderTests {

    // MARK: - Tile name generation

    @Test func tileNameNorthEast() {
        let coord = CLLocationCoordinate2D(latitude: 46.5, longitude: 7.8)
        #expect(DEMTileManager.tileName(for: coord) == "N46E007")
    }

    @Test func tileNameNorthWest() {
        let coord = CLLocationCoordinate2D(latitude: 46.5, longitude: -7.8)
        #expect(DEMTileManager.tileName(for: coord) == "N46W008")
    }

    @Test func tileNameSouthEast() {
        let coord = CLLocationCoordinate2D(latitude: -33.9, longitude: 151.2)
        #expect(DEMTileManager.tileName(for: coord) == "S34E151")
    }

    @Test func tileNameExactBoundary() {
        let coord = CLLocationCoordinate2D(latitude: 47.0, longitude: 8.0)
        #expect(DEMTileManager.tileName(for: coord) == "N47E008")
    }

    // MARK: - Required tiles

    @Test func requiredTilesCountNonPolar() {
        let coord = CLLocationCoordinate2D(latitude: 47.07, longitude: 12.69)
        let tiles = DEMTileManager.requiredTiles(for: coord, radiusKm: 80)
        #expect(tiles.count >= 9)
        #expect(tiles.count <= 25)
    }

    @Test func requiredTilesContainUserTile() {
        let coord = CLLocationCoordinate2D(latitude: 45.97, longitude: 7.65)
        let tiles = DEMTileManager.requiredTiles(for: coord)
        #expect(tiles.contains("N45E007"))
    }

    // MARK: - Bearing calculation

    @Test func azimuthZermattToMatterhorn() {
        // Matterhorn is WSW of Zermatt — computed bearing ≈ 235° (matches GeometryTests reference)
        let from = CLLocationCoordinate2D(latitude: 46.0207, longitude: 7.7491)
        let to = CLLocationCoordinate2D(latitude: 45.9765, longitude: 7.6585)
        let bearing = PeakFinderService.calculateAzimuth(from: from, to: to)
        #expect(bearing > 220)
        #expect(bearing < 255)
    }

    @Test func azimuthDueNorth() {
        let from = CLLocationCoordinate2D(latitude: 46.0, longitude: 8.0)
        let to = CLLocationCoordinate2D(latitude: 47.0, longitude: 8.0)
        let bearing = PeakFinderService.calculateAzimuth(from: from, to: to)
        #expect(abs(bearing - 0.0) < 1.0 || abs(bearing - 360.0) < 1.0)
    }

    @Test func azimuthDueEast() {
        let from = CLLocationCoordinate2D(latitude: 46.0, longitude: 8.0)
        let to = CLLocationCoordinate2D(latitude: 46.0, longitude: 9.0)
        let bearing = PeakFinderService.calculateAzimuth(from: from, to: to)
        #expect(abs(bearing - 90.0) < 2.0)
    }

    @Test func azimuthWrapAroundBoundary() {
        let heading = 355.0
        let peakAzimuth = 5.0
        let delta = (peakAzimuth - heading + 540).truncatingRemainder(dividingBy: 360) - 180
        #expect(abs(delta - 10.0) < 0.001)
    }

    // MARK: - Elevation angle

    @Test func elevationAngleFlat() {
        let angle = elevAngle(altDiff: 0, distanceMetres: 1000)
        #expect(abs(angle) < 0.1)
    }

    @Test func elevationAngleUphill() {
        let angle = elevAngle(altDiff: 100, distanceMetres: 1000)
        #expect(abs(angle - 5.71) < 0.1)
    }

    @Test func elevationAngleCurvatureCorrection() {
        let distanceMetres = 80_000.0
        let curveCorrection = (distanceMetres * distanceMetres) / (2.0 * 6_371_000.0)
        let angle = elevAngle(altDiff: curveCorrection, distanceMetres: distanceMetres)
        #expect(abs(angle) < 0.2)
    }

    // MARK: - Helpers

    private func elevAngle(altDiff: Double, distanceMetres: Double) -> Double {
        let curveCorrection = (distanceMetres * distanceMetres) / (2.0 * 6_371_000.0)
        let correctedDiff = altDiff - curveCorrection
        return atan2(correctedDiff, distanceMetres) * 180.0 / .pi
    }
}
