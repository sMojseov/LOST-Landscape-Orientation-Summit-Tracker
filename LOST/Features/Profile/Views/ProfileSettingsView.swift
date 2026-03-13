import SwiftUI

struct ProfileSettingsView: View {
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
                    
                    Text("PROFILE SETTINGS")
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
                            Text("USERNAME")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                            Spacer()
                            TextField("Username", text: $settingsManager.username)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                        
                        HStack {
                            Text("EMAIL")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                            Spacer()
                            TextField("Email", text: $settingsManager.email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                    } header: {
                        Text("IDENTIFICATION")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.4))
                    }
                    .listRowBackground(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.5))
                    
                    Section {
                        HStack {
                            Text("AGE")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                            Spacer()
                            Stepper("\(settingsManager.age)", value: $settingsManager.age, in: 1...120)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                        
                        HStack {
                            Text("HEIGHT")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                            Spacer()
                            HStack(spacing: 4) {
                                TextField("Height", value: $settingsManager.height, formatter: NumberFormatter())
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 50)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                Text("CM")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.4))
                            }
                        }
                    } header: {
                        Text("PHYSICAL SPECS")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.4))
                    }
                    .listRowBackground(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.5))
                    
                    Section {
                        Picker("THEME MODE", selection: $settingsManager.theme) {
                            ForEach(AppTheme.allCases) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.5))
                    } header: {
                        Text("SYSTEM INTERFACE")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.4))
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    ProfileSettingsView()
        .environmentObject(SettingsManager())
}
