import SwiftUI
import Combine

enum AppTheme: String, CaseIterable, Identifiable {
    case light = "LIGHT"
    case dark = "DARK"
    case system = "SYSTEM"
    
    var id: String { self.rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

class SettingsManager: ObservableObject {
    @AppStorage("app_theme") var theme: AppTheme = .dark
    @AppStorage("user_email") var email: String = "stefan@lost-app.com"
    @AppStorage("user_age") var age: Int = 28
    @AppStorage("user_height") var height: Int = 185 // in cm
    @AppStorage("user_username") var username: String = "STEFAN MOJSEOV"
    
    // Emergency Info
    @AppStorage("emergency_blood_type") var bloodType: String = ""
    @AppStorage("emergency_contact_name") var emergencyContactName: String = ""
    @AppStorage("emergency_contact_phone") var emergencyContactPhone: String = ""
}
