//
//  LOSTApp.swift
//  LOST
//
//  Created by Stefan Mojseov on 04.03.26.
//

import SwiftUI

@main
struct LOSTApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var settingsManager = SettingsManager()
    
    init() {
        WatchConnectivityManager.shared.activate()

        // Standard TabBar customization for visibility
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.clear
        
        // Unselected icon and text color
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            TabView(selection: $appState.selectedTab) {
                ScanningView()
                    .tag(AppState.Tab.scan.rawValue)
                    .tabItem {
                        Label("Scan", systemImage: "mountain.2")
                    }
                
                TopoMapView()
                    .environmentObject(appState)
                    .tag(AppState.Tab.map.rawValue)
                    .tabItem {
                        Label("Map", systemImage: "map")
                    }
                
                ExploreView()
                    .environmentObject(appState)
                    .tag(AppState.Tab.explore.rawValue)
                    .tabItem {
                        Label("Explore", systemImage: "magnifyingglass")
                    }
                
                PlanHikeView()
                    .tag(AppState.Tab.hike.rawValue)
                    .tabItem {
                        Label("Hike", systemImage: "figure.hiking")
                    }

                StatsView()
                    .environmentObject(appState)
                    .environmentObject(settingsManager)
                    .tag(AppState.Tab.stats.rawValue)
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar.fill")
                    }

                ProfileView()
                    .environmentObject(appState)
                    .environmentObject(settingsManager)
                    .tag(AppState.Tab.profile.rawValue)
                    .tabItem {
                        Label("Profile", systemImage: "person.circle")
                    }
            }
            .accentColor(settingsManager.theme.colorScheme == .light ? Color.deepForest : Color.sageGreen)
            .ignoresSafeArea(.keyboard)
            .environmentObject(appState)
            .environmentObject(settingsManager)
            .preferredColorScheme(settingsManager.theme.colorScheme)
        }
    }
}
