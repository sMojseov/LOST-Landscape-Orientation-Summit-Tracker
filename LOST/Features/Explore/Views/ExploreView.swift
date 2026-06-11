//
//  ExploreView.swift
//  LOST
//
//  Created by Stefan Mojseov on 04.03.26.
//

import SwiftUI
import CoreLocation

struct ExploreView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var isSearching = false
    @AppStorage("selectedFilter") private var selectedFilter = "All"
    @State var nearbyNote: String = ""

    let filters = ["All", "4000m+", "Nearby", "Saved"]

    var filteredMountains: [Mountain] {
        var result = Mountain.data
        if !searchText.isEmpty {
            result = result.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
        if selectedFilter == "4000m+" {
            result = result.filter { $0.elevation >= 4000 }
        }
        if selectedFilter == "Nearby" {
            if let userLocation = locationManager.userLocation {
                result = Array(result.sorted(by: {
                    let a = CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
                    let b = CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude)
                    return userLocation.distance(from: a) < userLocation.distance(from: b)
                }).prefix(8))
            }
            // If userLocation is nil, return all (nearbyNote is set via onChange)
        }
        return result
    }
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color.earthyBeige).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header & Search Bar
                VStack(alignment: .leading, spacing: 16) {
                    // Intel Pill
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.sageGreen)
                            .frame(width: 4, height: 4)
                        Text("Intel")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.sageGreen)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.sageGreen.opacity(0.12)))
                    .overlay(Capsule().stroke(Color.sageGreen.opacity(0.3), lineWidth: 0.5))
                    .padding(.horizontal)
                    .padding(.top)
                    
                    Text("Explore peaks")
                        .font(.title2.bold())
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .padding(.horizontal)
                    
                    // Search Bar
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.sageGreen)
                            
                            TextField("Search mountains...", text: $searchText, onEditingChanged: { editing in
                                withAnimation {
                                    isSearching = editing
                                }
                            })
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .font(.body)
                            
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.3))
                                }
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        
                        if isSearching || !searchText.isEmpty {
                            Button("Exit") {
                                withAnimation {
                                    searchText = ""
                                    isSearching = false
                                    hideKeyboard()
                                }
                            }
                            .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                            .font(.system(size: 14, weight: .bold))
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)
                    
                    // Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(filters, id: \.self) { filter in
                                Button {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                        selectedFilter = filter
                                    }
                                } label: {
                                    Text(filter)
                                        .font(.system(size: 13, weight: selectedFilter == filter ? .semibold : .medium))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selectedFilter == filter ? Color.sageGreen.opacity(0.15) : Color.white.opacity(0.06))
                                        .foregroundColor(selectedFilter == filter ? .sageGreen : .white.opacity(0.5))
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(selectedFilter == filter ? Color.sageGreen.opacity(0.4) : Color.white.opacity(0.12), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    if selectedFilter == "Nearby" && !nearbyNote.isEmpty {
                        Text(nearbyNote)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.horizontal)
                    }

                    Spacer().frame(height: 8)
                }
                .padding(.top)
                
                // Results List
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(searchText.isEmpty ? "All peaks" : "Search results")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        VStack(spacing: 12) {
                            let mountains = filteredMountains
                            ForEach(Array(mountains.enumerated()), id: \.element.id) { index, mountain in
                                MountainRow(mountain: mountain, isFirst: index == 0 && searchText.isEmpty) {
                                    appState.navigateToMap(with: mountain)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .onChange(of: selectedFilter) { _, newFilter in
            if newFilter == "Nearby" && locationManager.userLocation == nil {
                nearbyNote = "Location unavailable — showing all mountains"
            } else {
                nearbyNote = ""
            }
        }
        .onChange(of: locationManager.userLocation) { _, newLocation in
            if selectedFilter == "Nearby" {
                nearbyNote = newLocation == nil
                    ? "Location unavailable — showing all mountains"
                    : ""
            }
        }
    }
}

struct MountainRow: View {
    let mountain: Mountain
    let isFirst: Bool
    let onShowOnMap: () -> Void
    @State private var isExpanded = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            if isFirst {
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.sageGreen.opacity(0.5), .clear]), startPoint: .leading, endPoint: .trailing))
                    .frame(height: 2)
            }
            
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    // Mountain Icon
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.sageGreen.opacity(0.1))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "mountain.2.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color.sageGreen.opacity(0.7))
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mountain.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        Text("\(mountain.country) · \(mountain.range)")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(mountain.elevation)M")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.sageGreen)
                        
                        Text(mountain.country)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .padding()
                .background(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider().background(Color.sageGreen.opacity(0.2))
                    
                    Text("Range: \(mountain.range)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.7))
                    
                    Button {
                        onShowOnMap()
                    } label: {
                        HStack {
                            Image(systemName: "map.fill")
                            Text("View on topo map")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(colorScheme == .dark ? Color.sageGreen : Color.deepForest)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding()
                .background(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isExpanded ? Color.sageGreen.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

#Preview {
    ExploreView()
        .environmentObject(AppState())
}
