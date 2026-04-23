import Foundation
import CoreLocation
import MapKit

class NearestRoadService {
    struct RoadResult {
        let name: String
        let coordinate: CLLocationCoordinate2D
        let distanceMeters: Double
        let bearingDegrees: Double
        let mapItem: MKMapItem
    }

    static func find(from location: CLLocation) async -> RoadResult? {
        // First try reverse geocoding — if already near a named road, use that
        if let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first,
           let thoroughfare = placemark.thoroughfare,
           let loc = placemark.location {
            let dist = location.distance(from: loc)
            if dist < 200 {
                let item = MKMapItem(placemark: MKPlacemark(coordinate: loc.coordinate))
                item.name = thoroughfare
                return RoadResult(
                    name: thoroughfare,
                    coordinate: loc.coordinate,
                    distanceMeters: dist,
                    bearingDegrees: bearing(from: location.coordinate, to: loc.coordinate),
                    mapItem: item
                )
            }
        }

        // Search for the nearest mapped street/road in a 10 km radius
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "road"
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 10_000,
            longitudinalMeters: 10_000
        )

        let results = (try? await MKLocalSearch(request: request).start())?.mapItems ?? []

        let nearest = results.min { a, b in
            let da = CLLocation(latitude: a.placemark.coordinate.latitude,
                                longitude: a.placemark.coordinate.longitude).distance(from: location)
            let db = CLLocation(latitude: b.placemark.coordinate.latitude,
                                longitude: b.placemark.coordinate.longitude).distance(from: location)
            return da < db
        }

        guard let item = nearest else { return nil }
        let dest = CLLocation(latitude: item.placemark.coordinate.latitude,
                              longitude: item.placemark.coordinate.longitude)
        let name = item.placemark.thoroughfare
            ?? item.placemark.name
            ?? item.name
            ?? "Nearest road"

        return RoadResult(
            name: name,
            coordinate: item.placemark.coordinate,
            distanceMeters: location.distance(from: dest),
            bearingDegrees: bearing(from: location.coordinate, to: item.placemark.coordinate),
            mapItem: item
        )
    }

    // Returns bearing in degrees (0 = North, clockwise)
    private static func bearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        var bearing = atan2(y, x) * 180 / .pi
        if bearing < 0 { bearing += 360 }
        return bearing
    }
}
