import Foundation
import CoreLocation

struct Mountain: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let elevation: Int // in meters
    let range: String
    let country: String
    let coordinate: CLLocationCoordinate2D
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Mountain, rhs: Mountain) -> Bool {
        lhs.id == rhs.id
    }
}

extension Mountain {
    static let data: [Mountain] = [
        // Germany
        Mountain(name: "Zugspitze", elevation: 2962, range: "Wetterstein Mountains", country: "Germany", coordinate: CLLocationCoordinate2D(latitude: 47.4211, longitude: 10.9848)),
        Mountain(name: "Watzmann", elevation: 2713, range: "Berchtesgaden Alps", country: "Germany", coordinate: CLLocationCoordinate2D(latitude: 47.5539, longitude: 12.9222)),
        Mountain(name: "Hochwanner", elevation: 2744, range: "Wetterstein Mountains", country: "Germany", coordinate: CLLocationCoordinate2D(latitude: 47.3942, longitude: 11.0475)),
        Mountain(name: "Leutascher Dreitorspitze", elevation: 2682, range: "Wetterstein Mountains", country: "Germany", coordinate: CLLocationCoordinate2D(latitude: 47.4103, longitude: 11.0506)),
        Mountain(name: "Hochfrottspitze", elevation: 2649, range: "Allgäu Alps", country: "Germany", coordinate: CLLocationCoordinate2D(latitude: 47.3000, longitude: 10.2786)),
        
        // Swiss Alps
        Mountain(name: "Matterhorn", elevation: 4478, range: "Pennine Alps", country: "Switzerland/Italy", coordinate: CLLocationCoordinate2D(latitude: 45.9765, longitude: 7.6585)),
        Mountain(name: "Eiger", elevation: 3967, range: "Bernese Alps", country: "Switzerland", coordinate: CLLocationCoordinate2D(latitude: 46.5775, longitude: 8.0053)),
        Mountain(name: "Jungfrau", elevation: 4158, range: "Bernese Alps", country: "Switzerland", coordinate: CLLocationCoordinate2D(latitude: 46.5367, longitude: 7.9625)),
        Mountain(name: "Mönch", elevation: 4107, range: "Bernese Alps", country: "Switzerland", coordinate: CLLocationCoordinate2D(latitude: 46.5583, longitude: 7.9967)),
        Mountain(name: "Piz Bernina", elevation: 4049, range: "Bernina Range", country: "Switzerland/Italy", coordinate: CLLocationCoordinate2D(latitude: 46.3822, longitude: 9.9081)),
        Mountain(name: "Dufourspitze", elevation: 4634, range: "Pennine Alps", country: "Switzerland/Italy", coordinate: CLLocationCoordinate2D(latitude: 45.9369, longitude: 7.8672)),
        
        // French Alps
        Mountain(name: "Mont Blanc", elevation: 4808, range: "Mont Blanc massif", country: "France/Italy", coordinate: CLLocationCoordinate2D(latitude: 45.8326, longitude: 6.8651)),
        Mountain(name: "Barre des Écrins", elevation: 4102, range: "Écrins Massif", country: "France", coordinate: CLLocationCoordinate2D(latitude: 44.9172, longitude: 6.3575)),
        Mountain(name: "Grand Casse", elevation: 3855, range: "Vanoise Massif", country: "France", coordinate: CLLocationCoordinate2D(latitude: 45.4183, longitude: 6.7553)),
        
        // Austrian Alps
        Mountain(name: "Großglockner", elevation: 3798, range: "Hohe Tauern", country: "Austria", coordinate: CLLocationCoordinate2D(latitude: 47.0745, longitude: 12.6939)),
        Mountain(name: "Wildspitze", elevation: 3770, range: "Ötztal Alps", country: "Austria", coordinate: CLLocationCoordinate2D(latitude: 46.8853, longitude: 10.8675)),
        Mountain(name: "Großvenediger", elevation: 3657, range: "Hohe Tauern", country: "Austria", coordinate: CLLocationCoordinate2D(latitude: 47.1089, longitude: 12.3456)),
        
        // Italian Alps (Dolomites etc.)
        Mountain(name: "Marmolada", elevation: 3343, range: "Dolomites", country: "Italy", coordinate: CLLocationCoordinate2D(latitude: 46.4356, longitude: 11.8500)),
        Mountain(name: "Gran Paradiso", elevation: 4061, range: "Graian Alps", country: "Italy", coordinate: CLLocationCoordinate2D(latitude: 45.5186, longitude: 7.2669)),
        Mountain(name: "Ortler", elevation: 3905, range: "Ortler Alps", country: "Italy", coordinate: CLLocationCoordinate2D(latitude: 46.5058, longitude: 10.5403))
    ]
}
