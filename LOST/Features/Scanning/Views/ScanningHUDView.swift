//
//  ScanningHUDView.swift
//  LOST
//
//  Created by Stefan Mojseov on 04.03.26.
//

import SwiftUI

struct ScanningHUDView: View {
    let altitude: String
    let heading: String
    let confidence: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            HUDGlassCard(label: "ALTITUDE", value: altitude)
            HUDGlassCard(label: "HEADING", value: heading)
            HUDGlassCard(label: "CONFIDENCE", value: confidence)
        }
        .padding()
        .background(colorScheme == .dark ? Color.black.opacity(0.8) : Color.earthyBeige.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(colorScheme == .dark ? Color.sageGreen.opacity(0.5) : Color.deepForest.opacity(0.3), lineWidth: 1)
        )
    }
}
