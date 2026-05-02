import SwiftUI
import CoreLocation
import Combine

class AppState: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var selectedMountain: Mountain?
    @Published var selectedRegion: Region?
    
    enum Tab: Int {
        case scan = 0
        case map = 1
        case explore = 2
        case hike = 3
        case profile = 4
        case stats = 5
    }
    
    func navigateToMap(with mountain: Mountain) {
        self.selectedMountain = mountain
        self.selectedRegion = nil
        self.selectedTab = Tab.map.rawValue
    }
    
    func navigateToMap(with region: Region) {
        self.selectedRegion = region
        self.selectedMountain = nil
        self.selectedTab = Tab.map.rawValue
    }
}
