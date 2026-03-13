//
//  ExploreView.swift
//  LOST
//
//  Created by Stefan Mojseov on 04.03.26.
//

import SwiftUI

struct ExploreView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText = ""
    @State private var isSearching = false
    
    var filteredMountains: [Mountain] {
        if searchText.isEmpty {
            return Mountain.data
        } else {
            return Mountain.data.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color.earthyBeige).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header & Search Bar
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("INTEL")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                            Text("EXPLORE PEAKS")
                                .font(.title2.bold())
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Search Bar
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                            
                            TextField("SEARCH MOUNTAINS...", text: $searchText, onEditingChanged: { editing in
                                withAnimation {
                                    isSearching = editing
                                }
                            })
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .font(.system(.body, design: .monospaced))
                            
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.3))
                                }
                            }
                        }
                        .padding(12)
                        .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(colorScheme == .dark ? Color.sageGreen.opacity(0.3) : Color.earthGold.opacity(0.4), lineWidth: 1)
                        )
                        
                        if isSearching || !searchText.isEmpty {
                            Button("EXIT") {
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
                    .padding(.bottom)
                }
                .background(colorScheme == .dark ? Color.black : Color.earthyBeige)
                .lostGlassStyle()
                .padding(.horizontal)
                .padding(.top)
                
                // Results List
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(searchText.isEmpty ? "ALL PEAKS" : "SEARCH RESULTS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        VStack(spacing: 12) {
                            ForEach(filteredMountains) { mountain in
                                MountainRow(mountain: mountain) {
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
    }
}

struct MountainRow: View {
    let mountain: Mountain
    let onShowOnMap: () -> Void
    @State private var isExpanded = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mountain.name.uppercased())
                            .font(.system(.headline, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        HStack {
                            Text("\(mountain.elevation)M")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                            
                            Text("•")
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.2))
                            
                            Text(mountain.country)
                                .font(.system(size: 12))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                        .font(.system(size: 14, weight: .bold))
                }
                .padding()
                .background(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider().background(colorScheme == .dark ? Color.sageGreen.opacity(0.2) : Color.deepForest.opacity(0.1))
                    
                    Text("RANGE: \(mountain.range)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.7))
                    
                    Button {
                        onShowOnMap()
                    } label: {
                        HStack {
                            Image(systemName: "map.fill")
                            Text("VIEW ON TOPO MAP")
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
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isExpanded ? (colorScheme == .dark ? Color.sageGreen.opacity(0.5) : Color.deepForest.opacity(0.3)) : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05)), lineWidth: 1)
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
