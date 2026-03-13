import SwiftUI

struct RegionSelectorView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Binding var selectedRegion: Region?
    @State private var searchText = ""
    
    var filteredRegions: [Region] {
        if searchText.isEmpty {
            return Region.data
        } else {
            return Region.data.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.description.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark ? Color.black : Color.earthyBeige).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                        TextField("Search regions...", text: $searchText)
                            .textFieldStyle(.plain)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                            }
                        }
                    }
                    .padding()
                    .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding()
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredRegions) { region in
                                Button(action: {
                                    selectedRegion = region
                                    dismiss()
                                }) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(region.name.uppercased())
                                                .font(.system(size: 16, weight: .black))
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                            Spacer()
                                            if selectedRegion?.id == region.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                                            }
                                        }
                                        
                                        Text(region.description)
                                            .font(.system(size: 12))
                                            .foregroundColor(colorScheme == .dark ? .sageGreen.opacity(0.8) : .deepForest.opacity(0.8))
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(selectedRegion?.id == region.id ? (colorScheme == .dark ? Color.sageGreen : Color.earthGold) : Color.clear, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("SELECT REGION")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                }
            }
        }
    }
}
