 import Foundation

struct Waypoint: Identifiable {
    let id = UUID()
    let name: String
    let elevation: Int
    let distanceFromStart: Double // km
    let estimatedMinutesFromStart: Int
    let isSummit: Bool
}
