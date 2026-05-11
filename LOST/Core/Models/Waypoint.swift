import Foundation
import CoreLocation

struct Waypoint: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let elevation: Int
    let distanceFromStart: Double // km
    let estimatedMinutesFromStart: Int
    let isSummit: Bool

    init(name: String, coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(), elevation: Int, distanceFromStart: Double, estimatedMinutesFromStart: Int, isSummit: Bool) {
        self.name = name
        self.coordinate = coordinate
        self.elevation = elevation
        self.distanceFromStart = distanceFromStart
        self.estimatedMinutesFromStart = estimatedMinutesFromStart
        self.isSummit = isSummit
    }
}
