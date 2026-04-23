import Foundation
import CoreLocation

struct Region: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let center: CLLocationCoordinate2D
    let zoomLevel: Double // Distance in meters for the camera
    let areaCoords: [CLLocationCoordinate2D] // Simple approximation of borders
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Region, rhs: Region) -> Bool {
        lhs.id == rhs.id
    }
}

extension Region {
    static let data: [Region] = [
        Region(
            name: "Zermatt-Cervinia",
            description: "Pennine Alps - High Alpine Glacier Region",
            center: CLLocationCoordinate2D(latitude: 45.9765, longitude: 7.6585),
            zoomLevel: 15000,
            areaCoords: [
                CLLocationCoordinate2D(latitude: 46.05, longitude: 7.55),
                CLLocationCoordinate2D(latitude: 46.05, longitude: 7.85),
                CLLocationCoordinate2D(latitude: 45.90, longitude: 7.85),
                CLLocationCoordinate2D(latitude: 45.90, longitude: 7.55)
            ]
        ),
        Region(
            name: "Mont Blanc Massif",
            description: "Graian Alps - Europe's Highest Peaks",
            center: CLLocationCoordinate2D(latitude: 45.8326, longitude: 6.8651),
            zoomLevel: 25000,
            areaCoords: [
                CLLocationCoordinate2D(latitude: 45.95, longitude: 6.70),
                CLLocationCoordinate2D(latitude: 45.95, longitude: 7.05),
                CLLocationCoordinate2D(latitude: 45.75, longitude: 7.05),
                CLLocationCoordinate2D(latitude: 45.75, longitude: 6.70)
            ]
        ),
        Region(
            name: "Bernese Oberland",
            description: "Swiss Alps - Eiger, Mönch & Jungfrau",
            center: CLLocationCoordinate2D(latitude: 46.5775, longitude: 8.0053),
            zoomLevel: 30000,
            areaCoords: [
                CLLocationCoordinate2D(latitude: 46.70, longitude: 7.80),
                CLLocationCoordinate2D(latitude: 46.70, longitude: 8.20),
                CLLocationCoordinate2D(latitude: 46.45, longitude: 8.20),
                CLLocationCoordinate2D(latitude: 46.45, longitude: 7.80)
            ]
        ),
        Region(
            name: "Dolomites SE",
            description: "Italian Alps - Marmolada & Cortina",
            center: CLLocationCoordinate2D(latitude: 46.4356, longitude: 11.8500),
            zoomLevel: 40000,
            areaCoords: [
                CLLocationCoordinate2D(latitude: 46.60, longitude: 11.60),
                CLLocationCoordinate2D(latitude: 46.60, longitude: 12.10),
                CLLocationCoordinate2D(latitude: 46.30, longitude: 12.10),
                CLLocationCoordinate2D(latitude: 46.30, longitude: 11.60)
            ]
        ),
        Region(
            name: "Hohe Tauern",
            description: "Austrian Alps - Großglockner Region",
            center: CLLocationCoordinate2D(latitude: 47.0745, longitude: 12.6939),
            zoomLevel: 35000,
            areaCoords: [
                CLLocationCoordinate2D(latitude: 47.20, longitude: 12.40),
                CLLocationCoordinate2D(latitude: 47.20, longitude: 13.00),
                CLLocationCoordinate2D(latitude: 46.90, longitude: 13.00),
                CLLocationCoordinate2D(latitude: 46.90, longitude: 12.40)
            ]
        ),
        Region(
            name: "Wetterstein",
            description: "Bavarian Alps - Zugspitze & Garmisch",
            center: CLLocationCoordinate2D(latitude: 47.4211, longitude: 10.9848),
            zoomLevel: 20000,
            areaCoords: [
                CLLocationCoordinate2D(latitude: 47.50, longitude: 10.80),
                CLLocationCoordinate2D(latitude: 47.50, longitude: 11.20),
                CLLocationCoordinate2D(latitude: 47.35, longitude: 11.20),
                CLLocationCoordinate2D(latitude: 47.35, longitude: 10.80)
            ]
        )
    ]
}
