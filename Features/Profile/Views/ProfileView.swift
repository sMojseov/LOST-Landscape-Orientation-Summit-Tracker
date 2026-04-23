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
    
    let summits = 42
    
    var levelInfo: (name: String, progress: Double, remaining: Int) {
        if summits < 10 {
            return ("Beginner", Double(summits) / 10.0, 10 - summits)
        } else if summits < 25 {
            return ("Intermediate", Double(summits - 10) / 15.0, 25 - summits)
        } else if summits < 50 {
            return ("Advanced", Double(summits - 25) / 25.0, 50 - summits)
        } else {
            return ("Expert", 1.0, 0)
        }
    }
    
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
                            StatCard(label: "SUMMITS IDENTIFIED", value: "\(summits)", icon: "mountain.2.fill")
                            StatCard(label: "GPS-DENIED DISTANCE", value: "124km", icon: "location.slash.fill")
                            StatCard(label: "TOTAL ASCENT", value: "12,450m", icon: "arrow.up.right")
                            StatCard(label: "EXPEDITIONS", value: "15", icon: "tent.fill")
                        }
                        .padding(.horizontal)
                        
                        // 1. Experience level bar
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Hiker level:")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                                Text(levelInfo.name)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.sageGreen)
                            }
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(LinearGradient(gradient: Gradient(colors: [.sageGreen, .earthGold]), startPoint: .leading, endPoint: .trailing))
                                        .frame(width: geo.size.width * levelInfo.progress, height: 8)
                                }
                            }
                            .frame(height: 8)
                            
                            if levelInfo.remaining > 0 {
                                Text("\(levelInfo.remaining) summits to next level")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                        .padding(.horizontal)
                        .lostGlassStyle()
                        .padding(.horizontal)
                        
                        // 2. Achievement badges
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Achievements")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    BadgeCard(name: "First Summit", icon: "mountain.2.fill", isUnlocked: summits >= 1)
                                    BadgeCard(name: "Above 4000m", icon: "cloud.fill", isUnlocked: summits >= 5)
                                    BadgeCard(name: "GPS-Free", icon: "location.slash.fill", isUnlocked: true)
                                    BadgeCard(name: "10 Scans", icon: "camera.viewfinder", isUnlocked: summits >= 10)
                                    BadgeCard(name: "Explorer", icon: "map.fill", isUnlocked: summits >= 25)
                                    BadgeCard(name: "Mountain Guide", icon: "figure.hiking", isUnlocked: summits >= 50)
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // 3. Summit log (last 3 scans)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent scans")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ScanRow(name: "Großglockner", location: "Hohe Tauern, Austria", confidence: "94%", date: "Today")
                                ScanRow(name: "Matterhorn", location: "Pennine Alps, Switzerland", confidence: "87%", date: "2 days ago")
                                ScanRow(name: "Zugspitze", location: "Wetterstein, Germany", confidence: "91%", date: "Last week")
                            }
                            .padding(.horizontal)
                        }
                        
                        // 4. Emergency info card
                        NavigationLink {
                            EmergencyInfoView()
                                .environmentObject(settingsManager)
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "shield.fill")
                                    .font(.title2)
                                    .foregroundColor(.red.opacity(0.7))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Emergency info")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("Blood type, emergency contact, medical notes")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                            .lostGlassStyle()
                            .padding(.horizontal)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
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

struct BadgeCard: View {
    let name: String
    let icon: String
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.sageGreen)
                .opacity(isUnlocked ? 1.0 : 0.25)
            
            Text(name)
                .font(.system(size: 10))
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(isUnlocked ? 0.8 : 0.25))
        }
        .frame(width: 80, height: 90)
        .overlay(alignment: .topTrailing) {
            if !isUnlocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(6)
            }
        }
        .lostGlassStyle()
    }
}

struct ScanRow: View {
    let name: String
    let location: String
    let confidence: String
    let date: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mountain.2.fill")
                .foregroundColor(.sageGreen)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text(location)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(confidence)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.sageGreen.opacity(0.15))
                    .foregroundColor(.sageGreen)
                    .clipShape(Capsule())
                
                Text(date)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .lostGlassStyle()
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
