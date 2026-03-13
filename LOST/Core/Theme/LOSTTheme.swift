//
//  LOSTTheme.swift
//  LOST
//
//  Created by Stefan Mojseov on 04.03.26.
//

import SwiftUI

extension Color {
    static let deepForest = AppColors.deepForest
    static let sageGreen = AppColors.sageGreen
    static let earthGold = AppColors.earthGold
    static let highlightCream = AppColors.highlightCream
    static let earthyBeige = AppColors.earthyBeige
}

struct LiquidGlassStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background {
                if colorScheme == .dark {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay(Color.sageGreen.opacity(0.1))
                } else {
                    Rectangle()
                        .fill(Color.highlightCream.opacity(0.4))
                        .blur(radius: 10)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.sageGreen.opacity(0.3) : Color.earthGold.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: Color.earthGold.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func lostGlassStyle() -> some View {
        self.modifier(LiquidGlassStyle())
    }
    
    func earthyBackground() -> some View {
        ZStack {
            if let colorScheme = (Mirror(reflecting: self).descendant("colorScheme") as? EnvironmentValues)?.colorScheme {
                if colorScheme == .dark {
                    Color.black.ignoresSafeArea()
                } else {
                    Color.earthyBeige.ignoresSafeArea()
                }
            } else {
                // Fallback for when colorScheme isn't directly accessible
                BackgroundHelper().ignoresSafeArea()
            }
            self
        }
    }
}

struct BackgroundHelper: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        if colorScheme == .dark {
            Color.black
        } else {
            Color.earthyBeige
        }
    }
}
