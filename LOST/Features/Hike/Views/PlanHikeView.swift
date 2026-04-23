//
//  PlanHikeView.swift
//  LOST
//
//  Created by Stefan Mojseov on 04.03.26.
//

import SwiftUI
import CoreLocation // Added import for CoreLocation

struct PlanHikeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var weatherService = HikeWeatherService()
    @State private var selectedMountain: Mountain?
    @State private var date = Date()
    @State private var difficulty = "Medium"   // "Easy", "Medium", "Expert"
    @State private var activeTab = "Plan"      // "Plan", "Weather", "Route"
    @State private var isShowingMountainPicker = false
    @State private var isShowingDatePicker = false
    @State private var mapDownloadState: MapDownloadState = .idle
    @State private var downloadProgress: Double = 0.0
    @State private var checklist: [String: Bool] = [
        "DEM data downloaded": false,
        "Emergency contact set": false,
        "Weather checked": false,
        "Map reviewed": false
    ]
    
    let tabs = ["Plan", "Weather", "Route"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("PLAN EXPEDITION")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(.sageGreen)
                            Text("Hike strategy")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Tab Selector
                    HStack(spacing: 8) {
                        ForEach(tabs, id: \.self) { tab in
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    activeTab = tab
                                }
                            } label: {
                                Text(tab)
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(activeTab == tab ? Color.sageGreen.opacity(0.15) : Color.white.opacity(0.06))
                                    .foregroundColor(activeTab == tab ? .sageGreen : .white.opacity(0.4))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(activeTab == tab ? Color.sageGreen.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(8)
                    .lostGlassStyle()
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            if activeTab == "Plan" {
                                planTab
                            } else if activeTab == "Weather" {
                                weatherTab
                            } else {
                                routeTab
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $isShowingMountainPicker) {
                MountainPickerView(selectedMountain: $selectedMountain)
            }
            .sheet(isPresented: $isShowingDatePicker) {
                VStack {
                    DatePicker("Select Date", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding()
                    Button("Done") {
                        isShowingDatePicker = false
                    }
                    .padding()
                }
                .presentationDetents([.medium])
            }
            .onAppear {
                if let mountain = selectedMountain {
                    weatherService.fetchForecast(latitude: mountain.coordinate.latitude, longitude: mountain.coordinate.longitude, date: date)
                }
            }
            .onChange(of: selectedMountain) { _, newMountain in // Updated onChange syntax
                if let mountain = newMountain {
                    weatherService.fetchForecast(latitude: mountain.coordinate.latitude, longitude: mountain.coordinate.longitude, date: date)
                }
            }
            .onChange(of: date) { _, newDate in // Updated onChange syntax
                if let mountain = selectedMountain {
                    weatherService.fetchForecast(latitude: mountain.coordinate.latitude, longitude: mountain.coordinate.longitude, date: newDate)
                }
            }
        }
    }
    
    // MARK: - Plan Tab
    private var planTab: some View {
        VStack(spacing: 16) {
            // Section A — Target peak selector
            SectionHeader(title: "Target peak")
            Button {
                isShowingMountainPicker = true
            } label: {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.sageGreen.opacity(0.1))
                        .frame(width: 36, height: 36)
                        .overlay(Image(systemName: "mountain.2.fill").foregroundColor(.sageGreen))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        if let mountain = selectedMountain {
                            Text(mountain.name)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            Text("\(mountain.range) · \(mountain.country)")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.4))
                        } else {
                            Text("Tap to select peak")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    Spacer()
                    
                    if let mountain = selectedMountain {
                        Text("\(mountain.elevation)m")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.sageGreen)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.3))
                }
                .lostGlassStyle()
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
            
            // Section B — Auto-calculated stats row
            if let mountain = selectedMountain {
                let distance = Double(mountain.elevation - 1000) / 400.0 + 8.0
                let ascent = mountain.elevation - 1000
                let estMinutes = (ascent / 400 * 60) + Int(distance / 4.0 * 60)
                let hours = estMinutes / 60
                let minutes = estMinutes % 60
                
                HStack(spacing: 12) {
                    StatMiniCard(label: "Distance", value: String(format: "%.1f km", distance))
                    StatMiniCard(label: "Ascent", value: "\(ascent) m")
                    StatMiniCard(label: "Est. time", value: "\(hours)h \(minutes)m")
                }
                .padding(.horizontal)
            }
            
            // Section C — Date picker
            SectionHeader(title: "Schedule")
            Button {
                isShowingDatePicker = true
            } label: {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.sageGreen)
                    Text(date, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated).year())
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("Change ›")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.sageGreen)
                }
                .lostGlassStyle()
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
            
            // Section D — Difficulty selector
            SectionHeader(title: "Difficulty")
            HStack(spacing: 12) {
                DifficultyPill(label: "Easy", activeColor: .sageGreen, current: $difficulty)
                DifficultyPill(label: "Medium", activeColor: .earthGold, current: $difficulty)
                DifficultyPill(label: "Expert", activeColor: .red.opacity(0.7), current: $difficulty)
            }
            .padding(.horizontal)
            
            // Section E — Pre-departure checklist
            SectionHeader(title: "Pre-departure checklist")
            VStack(spacing: 12) {
                ForEach(checklist.keys.sorted(), id: \.self) { key in
                    HStack {
                        Button {
                            checklist[key]?.toggle()
                        } label: {
                            Image(systemName: checklist[key] == true ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundColor(checklist[key] == true ? .sageGreen : .white.opacity(0.2))
                        }
                        
                        Text(key)
                            .font(.system(size: 14))
                            .foregroundColor(checklist[key] == true ? .white.opacity(0.4) : .white)
                            .strikethrough(checklist[key] == true)
                        
                        Spacer()
                        
                        if key == "DEM data downloaded" {
                            Button {
                                // Download TODO
                            } label: {
                                Text("Download")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.sageGreen)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.sageGreen.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    if key != checklist.keys.sorted().last {
                        Divider().background(Color.white.opacity(0.05))
                    }
                }
            }
            .lostGlassStyle()
            .padding(.horizontal)
            
            // Section F — Offline map download
            SectionHeader(title: "Offline map")
            offlineMapSection

            // Section G — Show on map button
            Button {
                if let mountain = selectedMountain {
                    appState.navigateToMap(with: mountain)
                }
            } label: {
                HStack {
                    Image(systemName: "map.fill")
                    Text("Show on map")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(selectedMountain != nil ? Color.sageGreen : Color.white.opacity(0.1))
                .foregroundColor(selectedMountain != nil ? .black : .white.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .opacity(selectedMountain != nil ? 1.0 : 0.4)
            }
            .disabled(selectedMountain == nil)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Offline Map Section
    private var offlineMapSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.sageGreen.opacity(0.1))
                    .frame(width: 36, height: 36)
                    .overlay(Image(systemName: "arrow.down.to.line.circle.fill").foregroundColor(.sageGreen).font(.system(size: 18)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedMountain.map { "\($0.name) Region" } ?? "Select a peak first")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(selectedMountain != nil ? .white : .white.opacity(0.4))
                    Text(mapDownloadState == .downloaded ? "Map available offline" : "Topographic + trails · ~45 MB")
                        .font(.system(size: 11))
                        .foregroundColor(mapDownloadState == .downloaded ? .sageGreen : .white.opacity(0.4))
                }

                Spacer()

                mapDownloadButton
            }

            if mapDownloadState == .downloading {
                VStack(spacing: 4) {
                    ProgressView(value: downloadProgress)
                        .tint(.sageGreen)
                        .animation(.linear, value: downloadProgress)
                    HStack {
                        Text("Downloading map tiles…")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.4))
                        Spacer()
                        Text("\(Int(downloadProgress * 100))%")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.sageGreen)
                    }
                }
            }

            if mapDownloadState == .downloaded {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.sageGreen)
                        .font(.system(size: 12))
                    Text("Ready for offline use")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.sageGreen)
                    Spacer()
                    Button {
                        mapDownloadState = .idle
                        downloadProgress = 0
                    } label: {
                        Text("Remove")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.red.opacity(0.7))
                    }
                }
            }
        }
        .lostGlassStyle()
        .padding(.horizontal)
    }

    @ViewBuilder
    private var mapDownloadButton: some View {
        switch mapDownloadState {
        case .idle:
            Button {
                guard selectedMountain != nil else { return }
                simulateMapDownload()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 13))
                    Text("Download")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(selectedMountain != nil ? .sageGreen : .white.opacity(0.3))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background((selectedMountain != nil ? Color.sageGreen : Color.white).opacity(0.1))
                .clipShape(Capsule())
            }
            .disabled(selectedMountain == nil)
        case .downloading:
            Button {
                mapDownloadState = .idle
                downloadProgress = 0
            } label: {
                Text("Cancel")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
            }
        case .downloaded:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.sageGreen)
                .font(.system(size: 22))
        }
    }

    private func simulateMapDownload() {
        mapDownloadState = .downloading
        downloadProgress = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.07, repeats: true) { t in
            downloadProgress += 0.02
            if downloadProgress >= 1.0 {
                downloadProgress = 1.0
                mapDownloadState = .downloaded
                t.invalidate()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
    }

    // MARK: - Weather Tab
    private var weatherTab: some View {
        VStack(spacing: 16) {
            if selectedMountain != nil { // Changed from 'if let mountain = selectedMountain'
                if weatherService.isLoading {
                    ProgressView()
                        .tint(.sageGreen)
                        .padding(.top, 40)
                } else if let error = weatherService.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else if let forecast = weatherService.forecast {
                    // Section A — Main forecast card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("\(forecast.tempMax)°C")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Text(forecast.weatherEmoji)
                                .font(.system(size: 32))
                        }
                        
                        Text(weatherDescription(for: forecast.weatherCode))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack(spacing: 24) {
                            WeatherMiniStat(label: "Wind", value: "\(forecast.windSpeed) km/h")
                            WeatherMiniStat(label: "Rain", value: "\(Int(forecast.precipitationSum))mm")
                            WeatherMiniStat(label: "Visibility", value: "~\(forecast.visibility)km")
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .overlay(Color.blue.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                    .padding(.horizontal)
                    
                    // Section B — Hourly forecast
                    SectionHeader(title: "Hourly forecast")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(forecast.hourly) { hour in
                                VStack(spacing: 6) {
                                    Text(hour.hour)
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(.white.opacity(0.4))
                                    Text(weatherEmoji(for: hour.weatherCode))
                                        .font(.system(size: 12))
                                    Text("\(hour.temp)°")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                                .frame(width: 42, height: 72)
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Section C — Safety assessment
                    SectionHeader(title: "Safety assessment")
                    VStack(spacing: 12) {
                        SafetyRow(label: "Wind conditions", status: forecast.windSafe ? "Safe" : "Strong", isSafe: forecast.windSafe)
                        SafetyRow(label: "Visibility", status: forecast.visibilitySafe ? "Good" : "Poor", isSafe: forecast.visibilitySafe)
                        SafetyRow(label: "Precipitation", status: forecast.precipSafe ? "Low" : "High", isSafe: forecast.precipSafe)
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        HStack {
                            Text("Overall verdict")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Text(forecast.overallGo ? "GO" : (forecast.precipSafe ? "CAUTION" : "NO-GO"))
                                .font(.system(size: 12, weight: .black))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(forecast.overallGo ? Color.sageGreen : (forecast.precipSafe ? Color.earthGold : Color.red.opacity(0.7)))
                                .foregroundColor(.black)
                                .clipShape(Capsule())
                        }
                    }
                    .lostGlassStyle()
                    .padding(.horizontal)
                    
                } else {
                    Text("Fetching forecast...")
                        .foregroundColor(.white.opacity(0.4))
                }
            } else {
                PlaceholderView(icon: "mountain.2.fill", text: "Select a peak first")
            }
        }
    }
    
    // MARK: - Route Tab
    private var routeTab: some View {
        VStack(spacing: 16) {
            if let mountain = selectedMountain {
                if mountain.waypoints.isEmpty {
                    PlaceholderView(icon: "map.fill", text: "No route data available")
                } else {
                    // Section A — Elevation profile chart
                    SectionHeader(title: "Elevation profile")
                    VStack {
                        ElevationChart(waypoints: mountain.waypoints)
                            .frame(height: 90)
                            .padding()
                    }
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // Section B — Time split row
                    HStack(spacing: 0) {
                        let totalMinutes = mountain.waypoints.last?.estimatedMinutesFromStart ?? 0
                        let descentMinutes = Int(Double(totalMinutes) / 2.4)
                        
                        TimeSplitCol(label: "Up", value: formatTime(minutes: totalMinutes))
                        Divider().frame(height: 30).background(Color.white.opacity(0.1))
                        TimeSplitCol(label: "Summit", value: formatArrival(minutes: totalMinutes))
                        Divider().frame(height: 30).background(Color.white.opacity(0.1))
                        TimeSplitCol(label: "Down", value: formatTime(minutes: descentMinutes))
                        Divider().frame(height: 30).background(Color.white.opacity(0.1))
                        TimeSplitCol(label: "Total", value: formatTime(minutes: totalMinutes + descentMinutes))
                    }
                    .padding(.vertical, 12)
                    .lostGlassStyle()
                    .padding(.horizontal)
                    
                    // Section C — Waypoints list
                    SectionHeader(title: "Waypoints")
                    VStack(spacing: 8) {
                        ForEach(Array(mountain.waypoints.enumerated()), id: \.offset) { index, wp in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(wp.isSummit ? Color.sageGreen : Color.white.opacity(0.1))
                                        .frame(width: 24, height: 24)
                                    if wp.isSummit {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.black)
                                    } else {
                                        Text("\(index + 1)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(wp.name)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("\(String(format: "%.1f", wp.distanceFromStart)) km from start")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                
                                Spacer()
                                
                                Text("\(wp.elevation)m")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.sageGreen)
                            }
                            .padding(12)
                            .background(wp.isSummit ? Color.sageGreen.opacity(0.07) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(wp.isSummit ? Color.sageGreen.opacity(0.3) : Color.clear, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                PlaceholderView(icon: "map.fill", text: "Select a peak first")
            }
        }
    }
    
    // MARK: - Helpers
    private func weatherDescription(for code: Int) -> String {
        switch code {
        case 0: return "Clear sky"
        case 1...3: return "Partly cloudy"
        case 45...48: return "Foggy"
        case 51...67: return "Rainy"
        case 71...77: return "Snowy"
        case 80...82: return "Rain showers"
        case 85...86: return "Snow showers"
        case 95...99: return "Thunderstorm"
        default: return "Cloudy"
        }
    }
    
    private func weatherEmoji(for code: Int) -> String {
        switch code {
        case 0: return "☀️"
        case 1...3: return "⛅"
        case 45...48: return "🌫"
        case 51...67: return "🌧"
        case 71...77: return "❄️"
        case 80...82: return "🌦"
        case 85...86: return "🌨"
        case 95...99: return "⛈"
        default: return "🌤"
        }
    }
    
    private func formatTime(minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return "\(h)h \(m)m"
    }
    
    private func formatArrival(minutes: Int) -> String {
        let departureHour = 9
        let arrivalMinutes = departureHour * 60 + minutes
        let h = (arrivalMinutes / 60) % 24
        let m = arrivalMinutes % 60
        let ampm = h >= 12 ? "PM" : "AM"
        let displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h)
        return String(format: "%d:%02d %@", displayH, m, ampm)
    }
}

// MARK: - Supporting Types

enum MapDownloadState {
    case idle, downloading, downloaded
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.sageGreen)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct StatMiniCard: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white.opacity(0.4))
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
    }
}

struct DifficultyPill: View {
    let label: String
    let activeColor: Color
    @Binding var current: String
    
    var body: some View {
        Button {
            current = label
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(current == label ? activeColor.opacity(0.2) : Color.white.opacity(0.06))
                .foregroundColor(current == label ? activeColor : .white.opacity(0.4))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(current == label ? activeColor.opacity(0.4) : Color.clear, lineWidth: 1))
        }
    }
}

struct WeatherMiniStat: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.4))
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

struct SafetyRow: View {
    let label: String
    let status: String
    let isSafe: Bool
    
    var body: some View {
        HStack {
            Circle()
                .fill(isSafe ? Color.sageGreen : Color.earthGold)
                .frame(width: 7, height: 7)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(status)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isSafe ? .sageGreen : .earthGold)
        }
    }
}

struct TimeSplitCol: View {
    let label: String
    let value: String
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white.opacity(0.4))
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PlaceholderView: View {
    let icon: String
    let text: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.2))
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.top, 60)
    }
}

struct MountainPickerView: View {
    @Binding var selectedMountain: Mountain?
    @State private var searchText = ""
    @Environment(\.dismiss) var dismiss
    
    var filteredMountains: [Mountain] {
        if searchText.isEmpty { return Mountain.data }
        return Mountain.data.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                List(filteredMountains) { mountain in
                    Button {
                        selectedMountain = mountain
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(mountain.name).bold().foregroundColor(.white)
                                Text("\(mountain.range) · \(mountain.country)").font(.caption).foregroundColor(.white.opacity(0.6))
                            }
                            Spacer()
                            Text("\(mountain.elevation)m").font(.caption.monospaced()).foregroundColor(.sageGreen)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
                .scrollContentBackground(.hidden)
                .searchable(text: $searchText, prompt: "Search peaks...")
            }
            .navigationTitle("Select Peak")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct ElevationChart: View {
    let waypoints: [Waypoint]
    
    var body: some View {
        Canvas { context, size in
            guard waypoints.count > 1 else { return }
            
            let maxDist = waypoints.last?.distanceFromStart ?? 1.0
            let minElev = waypoints.map { $0.elevation }.min() ?? 0
            let maxElev = waypoints.map { $0.elevation }.max() ?? 1000
            let range = Double(maxElev - minElev)
            
            func point(for wp: Waypoint) -> CGPoint {
                let x = CGFloat(wp.distanceFromStart / maxDist) * size.width
                let y = size.height - CGFloat(Double(wp.elevation - minElev) / range) * size.height
                return CGPoint(x: x, y: y)
            }
            
            var path = Path()
            path.move(to: point(for: waypoints[0]))
            for i in 1..<waypoints.count {
                path.addLine(to: point(for: waypoints[i]))
            }
            
            // Fill
            var fillPath = path
            fillPath.addLine(to: CGPoint(x: size.width, y: size.height))
            fillPath.addLine(to: CGPoint(x: 0, y: size.height))
            fillPath.closeSubpath()
            
            context.fill(fillPath, with: .linearGradient(Gradient(colors: [.sageGreen.opacity(0.35), .sageGreen.opacity(0.02)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
            
            // Stroke
            context.stroke(path, with: .color(.sageGreen.opacity(0.8)), lineWidth: 1.5)
            
            // Points
            for wp in waypoints {
                let p = point(for: wp)
                if wp.isSummit {
                    context.fill(Path(ellipseIn: CGRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8)), with: .color(.sageGreen))
                } else if wp.distanceFromStart == 0 {
                    context.fill(Path(ellipseIn: CGRect(x: p.x - 3, y: p.y - 3, width: 6, height: 6)), with: .color(.white.opacity(0.5)))
                }
            }
        }
    }
}

#Preview {
    PlanHikeView()
        .environmentObject(AppState())
}

