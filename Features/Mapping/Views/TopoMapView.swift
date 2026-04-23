//
//  TopoMapView.swift
//  LOST
//
//  Created by Stefan Mojseov on 04.03.26.
//

import SwiftUI
import MapKit
import CoreLocation

struct TopoMapView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var locationManager = LocationManager()
    @Environment(\.colorScheme) var colorScheme
    
    // Initial camera position (Matterhorn area)
    @State private var cameraPosition: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: 45.9765, longitude: 7.6585),
            distance: 5000,
            heading: 0,
            pitch: 45
        )
    )
    
    @State private var centerCoordinate = CLLocationCoordinate2D(latitude: 45.9765, longitude: 7.6585)
    @State private var isMapLoaded = false
    @State private var followUser = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background color while loading
            (colorScheme == .dark ? Color.black : Color.earthyBeige).ignoresSafeArea()
            
            // Apple Maps View
            if isMapLoaded {
                Map(position: $cameraPosition, interactionModes: .all) {
                    UserAnnotation()
                    
                    if let mountain = appState.selectedMountain {
                        Annotation(mountain.name, coordinate: mountain.coordinate) {
                            VStack(spacing: 0) {
                                Image(systemName: "mountain.2.fill")
                                    .padding(8)
                                    .background(colorScheme == .dark ? Color.sageGreen : Color.deepForest)
                                    .foregroundColor(colorScheme == .dark ? .black : .white)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(Color.white, lineWidth: 2)
                                    )
                                    .shadow(radius: 4)
                                
                                Image(systemName: "triangle.fill")
                                    .resizable()
                                    .frame(width: 10, height: 10)
                                    .foregroundColor(colorScheme == .dark ? Color.sageGreen : Color.deepForest)
                                    .rotationEffect(.degrees(180))
                                    .offset(y: -3)
                            }
                        }
                    }
                    
                    if let region = appState.selectedRegion {
                        MapPolygon(coordinates: region.areaCoords)
                            .foregroundStyle((colorScheme == .dark ? Color.sageGreen : Color.deepForest).opacity(0.15))
                            .stroke((colorScheme == .dark ? Color.sageGreen : Color.deepForest), lineWidth: 2)
                    }
                }
                .mapStyle(.hybrid(elevation: .realistic))
                .onMapCameraChange { context in
                    centerCoordinate = context.camera.centerCoordinate
                }
                .ignoresSafeArea()
                .transition(.opacity)
            } else {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .sageGreen : .deepForest))
                    Text("INITIALIZING SATELLITE LINK...")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? .sageGreen.opacity(0.7) : .deepForest.opacity(0.7))
                        .padding(.top, 8)
                }
            }
            
            // UI Overlays
            VStack {
                // Real-time Coordinate Overlay
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("COORDINATES")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? .sageGreen.opacity(0.7) : .deepForest.opacity(0.7))
                        
                        Text("\(String(format: "%.4f", centerCoordinate.latitude)) N, \(String(format: "%.4f", centerCoordinate.longitude)) E")
                            .font(.system(.subheadline, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    Spacer()
                    
                    // Location status indicator
                    Circle()
                        .fill(locationManager.userLocation != nil ? (colorScheme == .dark ? Color.sageGreen : Color.deepForest) : Color.red)
                        .frame(width: 8, height: 8)
                        .shadow(color: locationManager.userLocation != nil ? (colorScheme == .dark ? Color.sageGreen : Color.deepForest) : Color.red, radius: 4)
                }
                .lostGlassStyle()
                .padding(.horizontal)
                .padding(.top, 50)
                
                Spacer()
                
                // Bottom Controls
                HStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        // Clear Selection Button
                        if appState.selectedMountain != nil || appState.selectedRegion != nil {
                            Button {
                                appState.selectedMountain = nil
                                appState.selectedRegion = nil
                            } label: {
                                Image(systemName: "mappin.slash")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.red)
                                    .frame(width: 50, height: 50)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        
                        // Recenter Button
                        Button {
                            followUser.toggle()
                            if followUser {
                                withAnimation {
                                    cameraPosition = .userLocation(fallback: .automatic)
                                }
                            }
                        } label: {
                            Image(systemName: followUser ? "location.fill" : "location")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                                .frame(width: 50, height: 50)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(colorScheme == .dark ? Color.sageGreen.opacity(0.3) : Color.deepForest.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            // Delay map loading to prevent race conditions during view transitions
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    isMapLoaded = true
                }
            }
        }
        .onChange(of: appState.selectedMountain) { oldMountain, newMountain in
            if let mountain = newMountain {
                followUser = false
                withAnimation(.spring()) {
                    cameraPosition = .camera(
                        MapCamera(
                            centerCoordinate: mountain.coordinate,
                            distance: 3000,
                            heading: 0,
                            pitch: 60
                        )
                    )
                }
            }
        }
        .onChange(of: appState.selectedRegion) { oldRegion, newRegion in
            if let region = newRegion {
                followUser = false
                withAnimation(.easeInOut(duration: 2.0)) {
                    cameraPosition = .camera(
                        MapCamera(
                            centerCoordinate: region.center,
                            distance: region.zoomLevel,
                            heading: 0,
                            pitch: 30
                        )
                    )
                }
            }
        }
    }
}

#Preview {
    TopoMapView()
        .environmentObject(AppState())
}
