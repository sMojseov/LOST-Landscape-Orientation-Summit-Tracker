//
//  EmergencyInfoView.swift
//  LOST
//
//  Created by Stefan Mojseov on 13.03.26.
//

import SwiftUI

struct EmergencyInfoView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color.earthyBeige).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3.bold())
                            .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                    }
                    
                    Spacer()
                    
                    Text("EMERGENCY INFO")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Spacer()
                    
                    // Invisible spacer for centering
                    Image(systemName: "chevron.left")
                        .font(.title3.bold())
                        .opacity(0)
                }
                .padding()
                .background(colorScheme == .dark ? Color.black : Color.earthyBeige)
                .lostGlassStyle()
                .padding(.horizontal)
                
                List {
                    Section {
                        HStack {
                            Text("Blood type")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                            Spacer()
                            TextField("e.g. A+", text: $settingsManager.bloodType)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                        
                        HStack {
                            Text("Contact name")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                            Spacer()
                            TextField("Name", text: $settingsManager.emergencyContactName)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                        
                        HStack {
                            Text("Contact phone")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                            Spacer()
                            TextField("Phone number", text: $settingsManager.emergencyContactPhone)
                                .keyboardType(.phonePad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                    } header: {
                        Text("CRITICAL DATA")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.4))
                    }
                    .listRowBackground(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.5))
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    EmergencyInfoView()
        .environmentObject(SettingsManager())
}
