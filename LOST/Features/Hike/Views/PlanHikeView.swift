//
//  PlanHikeView.swift
//  LOST
//
//  Created by Stefan Mojseov on 04.03.26.
//

import SwiftUI

struct PlanHikeView: View {
    @EnvironmentObject var appState: AppState
    @State private var date = Date()
    @State private var selectedRegion: Region?
    @State private var showingRegionSelector = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color.earthyBeige).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("MISSION PLAN")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                            Text("PLAN YOUR HIKE")
                                .font(.title2.bold())
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                        Spacer()
                    }
                    .padding()
                    .lostGlassStyle()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("REGION")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                        
                        Button(action: { showingRegionSelector = true }) {
                            HStack {
                                Text(selectedRegion?.name ?? "SELECT REGION")
                                    .fontWeight(.bold)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                            }
                            .padding()
                            .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(colorScheme == .dark ? Color.sageGreen.opacity(0.3) : Color.earthGold.opacity(0.4), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        Text("DATE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                        
                        DatePicker("Select Date", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .accentColor(colorScheme == .dark ? .sageGreen : .deepForest)
                            .padding()
                            .background(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .colorScheme(colorScheme)
                        
                        Button(action: {
                            if let region = selectedRegion {
                                appState.navigateToMap(with: region)
                            }
                        }) {
                            HStack {
                                Image(systemName: "map.fill")
                                Text("SHOW IN MAP")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(colorScheme == .dark ? Color.sageGreen : Color.deepForest)
                            .foregroundColor(colorScheme == .dark ? .black : .white)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                        .opacity(selectedRegion == nil ? 0.5 : 1.0)
                        .disabled(selectedRegion == nil)
                        
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "icloud.and.arrow.down.fill")
                                Text("DOWNLOAD OFFLINE DEM")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                            .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top)
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showingRegionSelector) {
            RegionSelectorView(selectedRegion: $selectedRegion)
        }
    }
}

#Preview {
    PlanHikeView()
        .environmentObject(AppState())
}
