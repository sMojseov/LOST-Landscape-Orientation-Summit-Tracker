//
//  ScanningView.swift
//  LOST
//
//  Created by Stefan Mojseov on 04.03.26.
//

import SwiftUI

struct ScanningView: View {
    @State private var isScanning = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background: Camera Feed
            CameraView()
                .ignoresSafeArea()
            
            // Middle Layer: Horizon Reticle
            if isScanning {
                VStack {
                    Rectangle()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [10, 5]))
                        .frame(height: 1)
                        .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                        .shadow(color: (colorScheme == .dark ? Color.sageGreen : Color.deepForest).opacity(0.8), radius: 5)
                }
                .frame(maxWidth: .infinity)
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
                
                // Bottom HUD Cards
                HStack(spacing: 12) {
                    HUDGlassCard(label: "ALTITUDE", value: "1,240m")
                    HUDGlassCard(label: "HEADING", value: "284° NW")
                    HUDGlassCard(label: "CONFIDENCE", value: isScanning ? "98%" : "--")
                }
                .padding(.horizontal)
                .padding(.bottom, isScanning ? 120 : 100)
            }
            .animation(.spring(), value: isScanning)
        }
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
