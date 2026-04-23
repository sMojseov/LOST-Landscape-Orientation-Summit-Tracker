import Foundation
import CoreLocation

struct VisiblePeak: Identifiable, Equatable {
    let id: UUID
    let mountain: Mountain
    let azimuth: Double
    let elevationAngle: Double
    let distance: Double
    
    init(mountain: Mountain, azimuth: Double, elevationAngle: Double, distance: Double) {
        self.id = mountain.id
        self.mountain = mountain
        self.azimuth = azimuth
        self.elevationAngle = elevationAngle
        self.distance = distance
    }
}

class PeakFinderService {
    static func calculateAzimuth(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Double {
        let lat1 = source.latitude * .pi / 180
        let lon1 = source.longitude * .pi / 180
        let lat2 = destination.latitude * .pi / 180
        let lon2 = destination.longitude * .pi / 180
        
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        var azimuth = atan2(y, x) * 180 / .pi
        if azimuth < 0 { azimuth += 360 }
        return azimuth
    }
    
    static func findVisiblePeaks(
        userLocation: CLLocation,
        mountains: [Mountain],
        maxDistance: Double = 100_000
    ) -> [VisiblePeak] {
        var visiblePeaks: [VisiblePeak] = []
        
        for mountain in mountains {
            let mountainLoc = CLLocation(latitude: mountain.coordinate.latitude, longitude: mountain.coordinate.longitude)
            let distance = userLocation.distance(from: mountainLoc)
            
            if distance > maxDistance { continue }
            
            let azimuth = calculateAzimuth(from: userLocation.coordinate, to: mountain.coordinate)
            let heightDifference = Double(mountain.elevation) - userLocation.altitude
            let elevationAngle = atan2(heightDifference, distance) * 180 / .pi
            
            visiblePeaks.append(VisiblePeak(
                mountain: mountain,
                azimuth: azimuth,
                elevationAngle: elevationAngle,
                distance: distance
            ))
        }
        
        return visiblePeaks
    }
}
