import Foundation
import CoreLocation

struct Mountain: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let elevation: Int // in meters
    let range: String
    let country: String
    let coordinate: CLLocationCoordinate2D
    let waypoints: [Waypoint]

    init(name: String, elevation: Int, range: String, country: String, coordinate: CLLocationCoordinate2D, waypoints: [Waypoint] = []) {
        self.name = name
        self.elevation = elevation
        self.range = range
        self.country = country
        self.coordinate = coordinate
        self.waypoints = waypoints
    }

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
        Mountain(
            name: "Zugspitze",
            elevation: 2962,
            range: "Wetterstein Mountains",
            country: "Germany",
            coordinate: CLLocationCoordinate2D(latitude: 47.4211, longitude: 10.9848),
            waypoints: [
                Waypoint(name: "Ehrwald Gondola base", coordinate: CLLocationCoordinate2D(latitude: 47.4135, longitude: 10.9354), elevation: 1006, distanceFromStart: 0.0, estimatedMinutesFromStart: 0, isSummit: false),
                Waypoint(name: "Wiener-Neustädter Hut", coordinate: CLLocationCoordinate2D(latitude: 47.4218, longitude: 10.9736), elevation: 2209, distanceFromStart: 4.2, estimatedMinutesFromStart: 110, isSummit: false),
                Waypoint(name: "Zugspitze Summit", coordinate: CLLocationCoordinate2D(latitude: 47.4211, longitude: 10.9848), elevation: 2962, distanceFromStart: 9.1, estimatedMinutesFromStart: 260, isSummit: true)
            ]
        ),
        Mountain(
            name: "Watzmann",
            elevation: 2713,
            range: "Berchtesgaden Alps",
            country: "Germany",
            coordinate: CLLocationCoordinate2D(latitude: 47.5539, longitude: 12.9222),
            waypoints: [
                Waypoint(name: "Trailhead - Ramsau bei Berchtesgaden", coordinate: CLLocationCoordinate2D(latitude: 47.6065, longitude: 12.8977), elevation: 670, distanceFromStart: 0.0, estimatedMinutesFromStart: 0, isSummit: false),
                Waypoint(name: "Watzmannhaus", coordinate: CLLocationCoordinate2D(latitude: 47.5705, longitude: 12.9360), elevation: 1928, distanceFromStart: 5.6, estimatedMinutesFromStart: 150, isSummit: false),
                Waypoint(name: "Hocheck (2651m)", coordinate: CLLocationCoordinate2D(latitude: 47.5621, longitude: 12.9289), elevation: 2651, distanceFromStart: 9.2, estimatedMinutesFromStart: 270, isSummit: false),
                Waypoint(name: "Watzmann Mittelspitze Summit", coordinate: CLLocationCoordinate2D(latitude: 47.5539, longitude: 12.9222), elevation: 2713, distanceFromStart: 11.0, estimatedMinutesFromStart: 330, isSummit: true)
            ]
        ),
        Mountain(
            name: "Hochwanner",
            elevation: 2744,
            range: "Wetterstein Mountains",
            country: "Germany",
            coordinate: CLLocationCoordinate2D(latitude: 47.3942, longitude: 11.0475),
            waypoints: [
                Waypoint(name: "Trailhead - Ehrwald", coordinate: CLLocationCoordinate2D(latitude: 47.4050, longitude: 10.9350), elevation: 994, distanceFromStart: 0.0, estimatedMinutesFromStart: 0, isSummit: false),
                Waypoint(name: "Hochwanner Saddle", coordinate: CLLocationCoordinate2D(latitude: 47.4000, longitude: 11.0200), elevation: 2200, distanceFromStart: 7.8, estimatedMinutesFromStart: 210, isSummit: false),
                Waypoint(name: "Hochwanner Summit", coordinate: CLLocationCoordinate2D(latitude: 47.3942, longitude: 11.0475), elevation: 2744, distanceFromStart: 11.5, estimatedMinutesFromStart: 300, isSummit: true)
            ]
        ),
        Mountain(
            name: "Leutascher Dreitorspitze",
            elevation: 2682,
            range: "Wetterstein Mountains",
            country: "Germany",
            coordinate: CLLocationCoordinate2D(latitude: 47.4103, longitude: 11.0506),
            waypoints: [
                Waypoint(name: "Trailhead - Leutasch", coordinate: CLLocationCoordinate2D(latitude: 47.3845, longitude: 11.1459), elevation: 1136, distanceFromStart: 0.0, estimatedMinutesFromStart: 0, isSummit: false),
                Waypoint(name: "Erlsattel", coordinate: CLLocationCoordinate2D(latitude: 47.3960, longitude: 11.0870), elevation: 2240, distanceFromStart: 5.2, estimatedMinutesFromStart: 180, isSummit: false),
                Waypoint(name: "Dreitorspitze Summit", coordinate: CLLocationCoordinate2D(latitude: 47.4103, longitude: 11.0506), elevation: 2682, distanceFromStart: 7.8, estimatedMinutesFromStart: 240, isSummit: true)
            ]
        ),
        Mountain(
            name: "Hochfrottspitze",
            elevation: 2649,
            range: "Allgäu Alps",
            country: "Germany",
            coordinate: CLLocationCoordinate2D(latitude: 47.3000, longitude: 10.2786),
            waypoints: [
                Waypoint(name: "Trailhead - Oberstdorf", coordinate: CLLocationCoordinate2D(latitude: 47.4083, longitude: 10.2786), elevation: 814, distanceFromStart: 0.0, estimatedMinutesFromStart: 0, isSummit: false),
                Waypoint(name: "Rappenseehütte", coordinate: CLLocationCoordinate2D(latitude: 47.3300, longitude: 10.2600), elevation: 2091, distanceFromStart: 8.4, estimatedMinutesFromStart: 240, isSummit: false),
                Waypoint(name: "Hochfrottspitze Summit", coordinate: CLLocationCoordinate2D(latitude: 47.3000, longitude: 10.2786), elevation: 2649, distanceFromStart: 12.5, estimatedMinutesFromStart: 330, isSummit: true)
            ]
        ),

        // Swiss Alps
        Mountain(
            name: "Matterhorn",
            elevation: 4478,
            range: "Pennine Alps",
            country: "Switzerland/Italy",
            coordinate: CLLocationCoordinate2D(latitude: 45.9765, longitude: 7.6585),
            waypoints: [
                Waypoint(name: "Zermatt village", coordinate: CLLocationCoordinate2D(latitude: 46.0207, longitude: 7.7491), elevation: 1620, distanceFromStart: 0.0, estimatedMinutesFromStart: 0, isSummit: false),
                Waypoint(name: "Hörnli Hut", coordinate: CLLocationCoordinate2D(latitude: 45.9910, longitude: 7.6697), elevation: 3260, distanceFromStart: 8.5, estimatedMinutesFromStart: 240, isSummit: false),
                Waypoint(name: "Matterhorn Summit", coordinate: CLLocationCoordinate2D(latitude: 45.9765, longitude: 7.6585), elevation: 4478, distanceFromStart: 14.0, estimatedMinutesFromStart: 480, isSummit: true)
            ]
        ),
        Mountain(
            name: "Eiger",
            elevation: 3967,
            range: "Bernese Alps",
            country: "Switzerland",
            coordinate: CLLocationCoordinate2D(latitude: 46.5775, longitude: 8.0053),
            waypoints: [
                Waypoint(name: "Trailhead - Kleine Scheidegg", coordinate: CLLocationCoordinate2D(latitude: 46.5853, longitude: 7.9594), elevation: 2061, distanceFromStart: 0.0, estimatedMinutesFromStart: 0, isSummit: false),
                Waypoint(name: "Eiger Glacier Station", coordinate: CLLocationCoordinate2D(latitude: 46.5789, longitude: 7.9733), elevation: 2320, distanceFromStart: 2.1, estimatedMinutesFromStart: 75, isSummit: false),
                Waypoint(name: "Summit - Eiger", coordinate: CLLocationCoordinate2D(latitude: 46.5775, longitude: 8.0053), elevation: 3967, distanceFromStart: 6.4, estimatedMinutesFromStart: 300, isSummit: true)
            ]
        ),
        Mountain(
            name: "Jungfrau",
            elevation: 4158,
            range: "Bernese Alps",
            country: "Switzerland",
            coordinate: CLLocationCoordinate2D(latitude: 46.5367, longitude: 7.9625),
            waypoints: [
                Waypoint(name: "Trailhead - Jungfraujoch", coordinate: CLLocationCoordinate2D(latitude: 46.5474, longitude: 7.9716), elevation: 3466, distanceFromStart: 0.0, estimatedMinutesFromStart: 0, isSummit: false),
                Waypoint(name: "Rottalsattel", coordinate: CLLocationCoordinate2D(latitude: 46.5385, longitude: 7.9534), elevation: 3885, distanceFromStart: 1.4, estimatedMinutesFromStart: 90, isSummit: false),
                Waypoint(name: "Summit - Jungfrau", coordinate: CLLocationCoordinate2D(latitude: 46.5367, longitude: 7.9625), elevation: 4158, distanceFromStart: 2.5, estimatedMinutesFromStart: 180, isSummit: true)
            ]
        ),
        Mountain(
            name: "Mönch",
            elevation: 4107,
            range: "Bernese Alps",
            country: "Switzerland",
            coordinate: CLLocationCoordinate2D(latitude: 46.5583, longitude: 7.9967),
            waypoints: [
                Waypoint(name: "Trailhead - Jungfraujoch", coordinate: CLLocationCoordinate2D(latitude: 46.5474, longitude: 7.9716), elevation: 3466, distanceFromStart: 0.0, estimatedMinutesFromStart: 0, isSummit: false),
                Waypoint(name: "Mönchsjoch Hut", coordinate: CLLocationCoordinate2D(latitude: 46.5560, longitude: 7.9824), elevation: 3657, distanceFromStart: 1.8, estimatedMinutesFromStart: 90, isSummit: false),
                Waypoint(name: "Summit - Mönch", coordinate: CLLocationCoordinate2D(latitude: 46.5583, longitude: 7.9967), elevation: 4107, distanceFromStart: 3.8, estimatedMinutesFromStart: 210, isSummit: true)
            ]
        ),
        Mountain(
            name: "Piz Bernina",
            elevation: 4049,
            range: "Bernina Range",
            country: "Switzerland/Italy",
            coordinate: CLLocationCoordinate2D(latitude: 46.3822, longitude: 9.9081),
            waypoints: [
                Waypoint(name: "Trailhead - Morteratsch", coordinate: CLLocationCoordinate2D(latitude: 46.4297, longitude: 9.9386), elevation: 1896, distanceFromStart: 0.0, estimatedMinutesFromStart: 0, isSummit: false),
                Waypoint(name: "Boval Hut", coordinate: CLLocationCoordinate2D(latitude: 46.3931, longitude: 9.9350), elevation: 2495, distanceFromStart: 4.8, estimatedMinutesFromStart: 150, isSummit: false),
                Waypoint(name: "Summit - Piz Bernina", coordinate: CLLocationCoordinate2D(latitude: 46.3822, longitude: 9.9081), elevation: 4049, distanceFromStart: 11.2, estimatedMinutesFromStart: 420, isSummit: true)
            ]
        ),
        Mountain(
            name: "Dufourspitze",
            elevation: 4634,
            range: "Pennine Alps",
            country: "Switzerland/Italy",
            coordinate: CLLocationCoordinate2D(latitude: 45.9369, longitude: 7.8672),
            waypoints: [
                Waypoint(name: "Trailhead - Rotenboden", coordinate: CLLocationCoordinate2D(latitude: 45.9923, longitude: 7.8237), elevation: 2815, distanceFromStart: 0.0, estimatedMinutesFromStart: 0, isSummit: false),
                Waypoint(name: "Monte Rosa Hut", coordinate: CLLocationCoordinate2D(latitude: 45.9696, longitude: 7.8274), elevation: 2883, distanceFromStart: 3.5, estimatedMinutesFromStart: 150, isSummit: false),
                Waypoint(name: "Summit - Dufourspitze", coordinate: CLLocationCoordinate2D(latitude: 45.9369, longitude: 7.8672), elevation: 4634, distanceFromStart: 10.8, estimatedMinutesFromStart: 480, isSummit: true)
            ]
        ),

        // French Alps
        Mountain(
            name: "Mont Blanc",
            elevation: 4808,
            range: "Mont Blanc massif",
            country: "France/Italy",
            coordinate: CLLocationCoordinate2D(latitude: 45.8326, longitude: 6.8651),
            waypoints: [
                Waypoint(name: "Trailhead - Les Houches", coordinate: CLLocationCoordinate2D(latitude: 45.8936, longitude: 6.7963), elevation: 1008, distanceFromStart: 0.0, estimatedMinutesFromStart: 0, isSummit: false),
                Waypoint(name: "Tête Rousse Hut", coordinate: CLLocationCoordinate2D(latitude: 45.8596, longitude: 6.8255), elevation: 3167, distanceFromStart: 7.2, estimatedMinutesFromStart: 270, isSummit: false),
                Waypoint(name: "Summit - Mont Blanc", coordinate: CLLocationCoordinate2D(latitude: 45.8326, longitude: 6.8651), elevation: 4808, distanceFromStart: 13.8, estimatedMinutesFromStart: 480, isSummit: true)
            ]
        ),
        Mountain(
            name: "Barre des Écrins",
            elevation: 4102,
            range: "Écrins Massif",
            country: "France",
            coordinate: CLLocationCoordinate2D(latitude: 44.9172, longitude: 6.3575),
            waypoints: [
                Waypoint(name: "Trailhead - La Bérarde", coordinate: CLLocationCoordinate2D(latitude: 44.9253, longitude: 6.3154), elevation: 1738, distanceFromStart: 0.0, estimatedMinutesFromStart: 0, isSummit: false),
                Waypoint(name: "Refuge Adèle Planchard", coordinate: CLLocationCoordinate2D(latitude: 44.9206, longitude: 6.3319), elevation: 3173, distanceFromStart: 4.1, estimatedMinutesFromStart: 210, isSummit: false),
                Waypoint(name: "Barre des Écrins Summit", coordinate: CLLocationCoordinate2D(latitude: 44.9172, longitude: 6.3575), elevation: 4102, distanceFromStart: 7.8, estimatedMinutesFromStart: 420, isSummit: true)
            ]
        ),
        Mountain(
            name: "Grand Casse",
            elevation: 3855,
            range: "Vanoise Massif",
            country: "France",
            coordinate: CLLocationCoordinate2D(latitude: 45.4183, longitude: 6.7553),
            waypoints: [
                Waypoint(name: "Trailhead - Pralognan-la-Vanoise", coordinate: CLLocationCoordinate2D(latitude: 45.3877, longitude: 6.7228), elevation: 1418, distanceFromStart: 0.0, estimatedMinutesFromStart: 0, isSummit: false),
                Waypoint(name: "Refuge de la Vanoise", coordinate: CLLocationCoordinate2D(latitude: 45.3862, longitude: 6.8007), elevation: 2517, distanceFromStart: 6.2, estimatedMinutesFromStart: 180, isSummit: false),
                Waypoint(name: "Grand Casse Summit", coordinate: CLLocationCoordinate2D(latitude: 45.4183, longitude: 6.7553), elevation: 3855, distanceFromStart: 13.1, estimatedMinutesFromStart: 360, isSummit: true)
            ]
        ),

        // Austrian Alps
        Mountain(
            name: "Großglockner",
            elevation: 3798,
            range: "Hohe Tauern",
            country: "Austria",
            coordinate: CLLocationCoordinate2D(latitude: 47.0745, longitude: 12.6939),
            waypoints: [
                Waypoint(name: "Trailhead - Lucknerhaus", coordinate: CLLocationCoordinate2D(latitude: 47.0308, longitude: 12.7367), elevation: 1918, distanceFromStart: 0.0, estimatedMinutesFromStart: 0, isSummit: false),
                Waypoint(name: "Glorer Hut", coordinate: CLLocationCoordinate2D(latitude: 47.0534, longitude: 12.7029), elevation: 2642, distanceFromStart: 5.1, estimatedMinutesFromStart: 120, isSummit: false),
                Waypoint(name: "Erzherzog-Johann Hut", coordinate: CLLocationCoordinate2D(latitude: 47.0603, longitude: 12.6939), elevation: 3454, distanceFromStart: 10.2, estimatedMinutesFromStart: 240, isSummit: false),
                Waypoint(name: "Großglockner Summit", coordinate: CLLocationCoordinate2D(latitude: 47.0745, longitude: 12.6939), elevation: 3798, distanceFromStart: 13.0, estimatedMinutesFromStart: 310, isSummit: true)
            ]
        ),
        Mountain(
            name: "Wildspitze",
            elevation: 3770,
            range: "Ötztal Alps",
            country: "Austria",
            coordinate: CLLocationCoordinate2D(latitude: 46.8853, longitude: 10.8675),
            waypoints: [
                Waypoint(name: "Trailhead - Vent", coordinate: CLLocationCoordinate2D(latitude: 46.8527, longitude: 10.9050), elevation: 1895, distanceFromStart: 0.0, estimatedMinutesFromStart: 0, isSummit: false),
                Waypoint(name: "Breslauer Hütte", coordinate: CLLocationCoordinate2D(latitude: 46.8631, longitude: 10.9050), elevation: 2844, distanceFromStart: 4.0, estimatedMinutesFromStart: 120, isSummit: false),
                Waypoint(name: "Wildspitze Summit", coordinate: CLLocationCoordinate2D(latitude: 46.8853, longitude: 10.8675), elevation: 3770, distanceFromStart: 8.2, estimatedMinutesFromStart: 270, isSummit: true)
            ]
        ),
        Mountain(
            name: "Großvenediger",
            elevation: 3657,
            range: "Hohe Tauern",
            country: "Austria",
            coordinate: CLLocationCoordinate2D(latitude: 47.1089, longitude: 12.3456),
            waypoints: [
                Waypoint(name: "Trailhead - Innergschlöss", coordinate: CLLocationCoordinate2D(latitude: 47.0985, longitude: 12.3800), elevation: 1680, distanceFromStart: 0.0, estimatedMinutesFromStart: 0, isSummit: false),
                Waypoint(name: "Kürsinger Hütte", coordinate: CLLocationCoordinate2D(latitude: 47.1140, longitude: 12.4300), elevation: 2558, distanceFromStart: 5.3, estimatedMinutesFromStart: 150, isSummit: false),
                Waypoint(name: "Großvenediger Summit", coordinate: CLLocationCoordinate2D(latitude: 47.1089, longitude: 12.3456), elevation: 3657, distanceFromStart: 10.1, estimatedMinutesFromStart: 300, isSummit: true)
            ]
        ),

        // Italian Alps (Dolomites etc.)
        Mountain(
            name: "Marmolada",
            elevation: 3343,
            range: "Dolomites",
            country: "Italy",
            coordinate: CLLocationCoordinate2D(latitude: 46.4356, longitude: 11.8500),
            waypoints: [
                Waypoint(name: "Trailhead - Malga Ciapela", coordinate: CLLocationCoordinate2D(latitude: 46.4497, longitude: 11.8726), elevation: 1446, distanceFromStart: 0.0, estimatedMinutesFromStart: 0, isSummit: false),
                Waypoint(name: "Rifugio Pian dei Fiacconi", coordinate: CLLocationCoordinate2D(latitude: 46.4420, longitude: 11.8615), elevation: 2626, distanceFromStart: 3.2, estimatedMinutesFromStart: 120, isSummit: false),
                Waypoint(name: "Marmolada Summit (Punta Penia)", coordinate: CLLocationCoordinate2D(latitude: 46.4356, longitude: 11.8500), elevation: 3343, distanceFromStart: 5.8, estimatedMinutesFromStart: 240, isSummit: true)
            ]
        ),
        Mountain(
            name: "Gran Paradiso",
            elevation: 4061,
            range: "Graian Alps",
            country: "Italy",
            coordinate: CLLocationCoordinate2D(latitude: 45.5186, longitude: 7.2669),
            waypoints: [
                Waypoint(name: "Trailhead - Pont", coordinate: CLLocationCoordinate2D(latitude: 45.5458, longitude: 7.2217), elevation: 1960, distanceFromStart: 0.0, estimatedMinutesFromStart: 0, isSummit: false),
                Waypoint(name: "Vittorio Emanuele II Hut", coordinate: CLLocationCoordinate2D(latitude: 45.5280, longitude: 7.2410), elevation: 2732, distanceFromStart: 4.6, estimatedMinutesFromStart: 120, isSummit: false),
                Waypoint(name: "Summit - Gran Paradiso", coordinate: CLLocationCoordinate2D(latitude: 45.5186, longitude: 7.2669), elevation: 4061, distanceFromStart: 9.2, estimatedMinutesFromStart: 330, isSummit: true)
            ]
        ),
        Mountain(
            name: "Ortler",
            elevation: 3905,
            range: "Ortler Alps",
            country: "Italy",
            coordinate: CLLocationCoordinate2D(latitude: 46.5058, longitude: 10.5403),
            waypoints: [
                Waypoint(name: "Trailhead - Trafoi", coordinate: CLLocationCoordinate2D(latitude: 46.5408, longitude: 10.5386), elevation: 1542, distanceFromStart: 0.0, estimatedMinutesFromStart: 0, isSummit: false),
                Waypoint(name: "Payer Hütte", coordinate: CLLocationCoordinate2D(latitude: 46.5172, longitude: 10.5267), elevation: 3029, distanceFromStart: 4.8, estimatedMinutesFromStart: 210, isSummit: false),
                Waypoint(name: "Ortler Summit", coordinate: CLLocationCoordinate2D(latitude: 46.5058, longitude: 10.5403), elevation: 3905, distanceFromStart: 6.9, estimatedMinutesFromStart: 300, isSummit: true)
            ]
        ),

        // Additional Swiss peaks
        Mountain(
            name: "Dom",
            elevation: 4545,
            range: "Pennine Alps",
            country: "Switzerland",
            coordinate: CLLocationCoordinate2D(latitude: 46.0942, longitude: 7.8586),
            waypoints: [
                Waypoint(name: "Trailhead - Randa", coordinate: CLLocationCoordinate2D(latitude: 46.0986, longitude: 7.7817), elevation: 1408, distanceFromStart: 0.0, estimatedMinutesFromStart: 0, isSummit: false),
                Waypoint(name: "Dom Hut", coordinate: CLLocationCoordinate2D(latitude: 46.0906, longitude: 7.8114), elevation: 2940, distanceFromStart: 5.8, estimatedMinutesFromStart: 210, isSummit: false),
                Waypoint(name: "Summit - Dom", coordinate: CLLocationCoordinate2D(latitude: 46.0942, longitude: 7.8586), elevation: 4545, distanceFromStart: 10.4, estimatedMinutesFromStart: 450, isSummit: true)
            ]
        ),
        Mountain(
            name: "Weißhorn",
            elevation: 4505,
            range: "Pennine Alps",
            country: "Switzerland",
            coordinate: CLLocationCoordinate2D(latitude: 46.1036, longitude: 7.7156),
            waypoints: [
                Waypoint(name: "Trailhead - Randa", coordinate: CLLocationCoordinate2D(latitude: 46.0986, longitude: 7.7817), elevation: 1408, distanceFromStart: 0.0, estimatedMinutesFromStart: 0, isSummit: false),
                Waypoint(name: "Weisshorn Hut", coordinate: CLLocationCoordinate2D(latitude: 46.0997, longitude: 7.7358), elevation: 2932, distanceFromStart: 4.2, estimatedMinutesFromStart: 180, isSummit: false),
                Waypoint(name: "Summit - Weißhorn", coordinate: CLLocationCoordinate2D(latitude: 46.1036, longitude: 7.7156), elevation: 4505, distanceFromStart: 9.6, estimatedMinutesFromStart: 420, isSummit: true)
            ]
        )
    ]
}
