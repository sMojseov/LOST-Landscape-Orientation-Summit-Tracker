//
//  ScanningView.swift
//  LOST
//
//  Created by Stefan Mojseov on 04.03.26.
//

import SwiftUI
import CoreMotion
import CoreLocation
import Combine

struct ScanningView: View {
    @State private var isScanning = false
    @State private var roll: Double = 0.0
    @State private var pitch: Double = 0.0
    @StateObject private var locationManager = LocationManager()
    @Environment(\.colorScheme) var colorScheme
    
    private let motionManager = CMMotionManager()
    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = width * 4/3
            let cameraCenterY = geometry.size.height / 2
            let cameraTop = cameraCenterY - (height / 2)
            let cameraBottom = cameraCenterY + (height / 2)
            
            ZStack {
                // Background: Black screen
                Color.black.ignoresSafeArea()
                
                // Camera Feed: Constrained to 4:3
                CameraView()
                    .frame(width: width, height: height)
                    .clipped()
                    .position(x: geometry.size.width / 2, y: cameraCenterY)
                
                // 3x3 Alignment Grid
                if isScanning {
                    ZStack {
                        // Vertical Lines
                        HStack {
                            Spacer()
                            Rectangle().fill(Color.white.opacity(0.3)).frame(width: 1)
                            Spacer()
                            Rectangle().fill(Color.white.opacity(0.3)).frame(width: 1)
                            Spacer()
                        }
                        // Horizontal Lines
                        VStack {
                            Spacer()
                            Rectangle().fill(Color.white.opacity(0.3)).frame(height: 1)
                            Spacer()
                            Rectangle().fill(Color.white.opacity(0.3)).frame(height: 1)
                            Spacer()
                        }
                    }
                    .frame(width: width, height: height)
                    .position(x: geometry.size.width / 2, y: cameraCenterY)
                }
                
                // Middle Layer: Horizon Reticle & Leveling Line
                if isScanning {
                    // Existing Dashed Horizon Reticle (Static center)
                    VStack {
                        Rectangle()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [10, 5]))
                            .frame(height: 1)
                            .foregroundColor((colorScheme == .dark ? Color.sageGreen : Color.deepForest).opacity(0.3))
                    }
                    .frame(maxWidth: .infinity)
                    .position(x: geometry.size.width / 2, y: cameraCenterY)
                    
                    // Gyroscope Leveling & Stabilization Guide
                    ZStack {
                        // Leveling Line (Roll)
                        Rectangle()
                            .fill(abs(roll) < 2.0 ? (colorScheme == .dark ? Color.sageGreen : Color.deepForest) : (colorScheme == .dark ? Color.white : Color.yellow))
                            .frame(width: width * 0.7, height: 2)
                            .rotationEffect(.degrees(-roll))
                        
                        // Stabilization Guide (Pitch target)
                        // This circle moves up/down based on pitch to guide user to 0 pitch (level)
                        Circle()
                            .stroke(abs(pitch) < 2.0 ? (colorScheme == .dark ? Color.sageGreen : Color.deepForest) : .white, lineWidth: 2)
                            .frame(width: 40, height: 40)
                            .offset(y: CGFloat(pitch * 10)) // Moving guide
                            .opacity(0.8)
                        
                        // Numeric Roll Indicator
                        Text(String(format: "%.1f°", abs(roll)))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(abs(roll) < 2.0 ? (colorScheme == .dark ? Color.sageGreen : Color.deepForest) : .white)
                            .padding(4)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(4)
                            .offset(y: 60)
                            .rotationEffect(.degrees(-roll))
                    }
                    .position(x: geometry.size.width / 2, y: cameraCenterY)
                }
                
                // Top Layer: UI Elements
                VStack {
                    // Top Scanning Toggle
                    HStack {
                        Spacer()
                        Toggle(isOn: $isScanning) {
                            Text(isScanning ? "SCANNING ACTIVE" : "START SCANNING")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(isScanning ? (colorScheme == .dark ? .sageGreen : .deepForest) : .white)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: colorScheme == .dark ? .sageGreen : .deepForest))
                        .padding()
                        .lostGlassStyle()
                    }
                    .padding(.horizontal)
                    .padding(.top, 50)
                    
                    Spacer()
                    
                    // Bottom HUD Cards - Lowered below camera frame
                    VStack(spacing: 20) {
                        HStack(spacing: 12) {
                            HUDGlassCard(label: "ALTITUDE", value: String(format: "%.0fm", locationManager.altitude))
                            HUDGlassCard(label: "HEADING", value: formatHeading(locationManager.heading))
                            HUDGlassCard(label: "CONFIDENCE", value: isScanning ? calculateConfidence() : "--")
                        }
                        .padding(.horizontal)
                        // Ensure it's below cameraBottom but above safe area
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 10)
                    }
                }
            }
            .animation(.spring(), value: isScanning)
        }
        .onReceive(timer) { _ in
            if isScanning {
                if let data = motionManager.deviceMotion {
                    // Convert radians to degrees
                    roll = data.attitude.roll * 180 / .pi
                    pitch = data.attitude.pitch * 180 / .pi
                }
            }
        }
        .onAppear {
            startMotionUpdates()
        }
        .onDisappear {
            stopMotionUpdates()
        }
    }
    
    private func startMotionUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
            motionManager.startDeviceMotionUpdates()
        }
    }
    
    private func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    private func formatHeading(_ heading: CLHeading?) -> String {
        guard let h = heading else { return "--" }
        let degrees = h.magneticHeading
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW", "N"]
        let index = Int((degrees + 22.5) / 45.0) & 7
        return String(format: "%.0f° %@", degrees, directions[index])
    }
    
    private func calculateConfidence() -> String {
        // Mock confidence calculation based on stability
        let stability = max(0, 100 - abs(roll) - abs(pitch))
        return String(format: "%.0f%%", min(99, 85 + (stability / 10)))
    }
}

struct HUDGlassCard: View {
    let label: String
    let value: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor((colorScheme == .dark ? Color.sageGreen : Color.deepForest).opacity(0.7))
            
            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lostGlassStyle()
    }
}

#Preview {
    ScanningView()
}
