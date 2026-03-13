//
//  ProfileView.swift
//  LOST
//
//  Created by Stefan Mojseov on 04.03.26.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                (colorScheme == .dark ? Color.black : Color.earthyBeige).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Clickable Header leading to Settings
                        NavigationLink {
                            ProfileSettingsView()
                                .environmentObject(settingsManager)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("HIKER PROFILE")
                                        .font(.system(size: 12, weight: .black))
                                        .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                                    Text(settingsManager.username.uppercased())
                                        .font(.title2.bold())
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                }
                                Spacer()
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                            }
                            .lostGlassStyle()
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Stats Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            StatCard(label: "SUMMITS IDENTIFIED", value: "42", icon: "mountain.2.fill")
                            StatCard(label: "GPS-DENIED DISTANCE", value: "124km", icon: "location.slash.fill")
                            StatCard(label: "TOTAL ASCENT", value: "12,450m", icon: "arrow.up.right")
                            StatCard(label: "EXPEDITIONS", value: "15", icon: "tent.fill")
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding(.top)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
}

struct StatCard: View {
    let label: String
    let value: String
    let icon: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                Text(value)
                    .font(.title3.bold())
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lostGlassStyle()
    }
}

#Preview {
    ProfileView()
        .environmentObject(SettingsManager())
}
