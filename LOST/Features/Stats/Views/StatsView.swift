import SwiftUI

struct StatsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.colorScheme) var colorScheme

    private var records: [ScanRecord] { ScanRecord.loadAll() }

    private var totalScans: Int { records.count }

    private var uniquePeaks: Int { Set(records.map { $0.mountainName }).count }

    private var bestConfidence: Double { records.map { $0.confidenceScore }.max() ?? 0 }

    private var daysActive: Int {
        let calendar = Calendar.current
        let days = records.map { calendar.startOfDay(for: $0.date) }
        return Set(days).count
    }

    private var last6MonthsData: [(label: String, count: Int)] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<6).reversed().map { offset in
            guard let monthDate = calendar.date(byAdding: .month, value: -offset, to: now) else {
                return (label: "—", count: 0)
            }
            let comps = calendar.dateComponents([.year, .month], from: monthDate)
            let label = monthDate.formatted(.dateTime.month(.abbreviated))
            let count = records.filter { r in
                let rc = calendar.dateComponents([.year, .month], from: r.date)
                return rc.year == comps.year && rc.month == comps.month
            }.count
            return (label: label, count: count)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark ? Color.black : Color.earthyBeige).ignoresSafeArea()

                if records.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            headerPill
                            statsGrid
                            monthlyChart
                            recentScansList
                        }
                        .padding(.top)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }

    // MARK: - Sections

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "mountain.2")
                .font(.system(size: 48))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.2) : .black.opacity(0.2))
            Text("No scans yet. Start scanning peaks.")
                .font(.system(size: 15))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.4))
                .multilineTextAlignment(.center)
        }
    }

    private var headerPill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.sageGreen)
                .frame(width: 4, height: 4)
            Text("Stats")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.sageGreen)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.sageGreen.opacity(0.12)))
        .overlay(Capsule().stroke(Color.sageGreen.opacity(0.3), lineWidth: 0.5))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.system(size: 12, weight: .black))
                .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatsGridCard(label: "Total Scans", value: "\(totalScans)", icon: "camera.viewfinder")
                StatsGridCard(label: "Unique Peaks", value: "\(uniquePeaks)", icon: "mountain.2.fill")
                StatsGridCard(label: "Best Confidence",
                              value: String(format: "%.0f%%", bestConfidence),
                              icon: "checkmark.seal.fill")
                StatsGridCard(label: "Days Active", value: "\(daysActive)", icon: "calendar")
            }
            .padding(.horizontal)
        }
    }

    private var monthlyChart: some View {
        let data = last6MonthsData
        let maxCount = max(data.map { $0.count }.max() ?? 1, 1)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Activity")
                .font(.system(size: 12, weight: .black))
                .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                .padding(.horizontal)

            Canvas { context, size in
                let labelHeight: CGFloat = 18
                let chartHeight = size.height - labelHeight
                let count = CGFloat(data.count)
                let spacing: CGFloat = 8
                let barWidth = (size.width - spacing * (count - 1)) / count

                for (i, item) in data.enumerated() {
                    let x = CGFloat(i) * (barWidth + spacing)

                    // Bar
                    let barH = item.count > 0
                        ? chartHeight * CGFloat(item.count) / CGFloat(maxCount)
                        : 2
                    let barRect = CGRect(x: x, y: chartHeight - barH,
                                        width: barWidth, height: barH)
                    let barPath = Path(roundedRect: barRect, cornerRadius: 4)
                    context.fill(barPath, with: .color(
                        item.count > 0 ? Color.sageGreen : Color.white.opacity(0.1)
                    ))

                    // Month label
                    let resolved = context.resolve(
                        Text(item.label)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.5))
                    )
                    context.draw(resolved,
                                 at: CGPoint(x: x + barWidth / 2,
                                             y: chartHeight + labelHeight / 2),
                                 anchor: .center)
                }
            }
            .frame(height: 110)
            .lostGlassStyle()
            .padding(.horizontal)
        }
    }

    private var recentScansList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Scans")
                .font(.system(size: 12, weight: .black))
                .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)
                .padding(.horizontal)

            VStack(spacing: 10) {
                ForEach(Array(records.prefix(10))) { record in
                    StatsRecordRow(record: record)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Sub-components

struct StatsGridCard: View {
    let label: String
    let value: String
    let icon: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(colorScheme == .dark ? .sageGreen : .deepForest)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                Text(value)
                    .font(.title3.bold())
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lostGlassStyle()
    }
}

struct StatsRecordRow: View {
    let record: ScanRecord
    @Environment(\.colorScheme) var colorScheme

    private var confidenceColor: Color {
        if record.confidenceScore >= 75 { return .sageGreen }
        if record.confidenceScore >= 50 { return .earthGold }
        return Color.red.opacity(0.7)
    }

    private var relativeDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(record.date) { return "Today" }
        if calendar.isDateInYesterday(record.date) { return "Yesterday" }
        let days = abs(calendar.dateComponents([.day], from: record.date, to: Date()).day ?? 0)
        if days < 7 { return "\(days) days ago" }
        if days < 14 { return "Last week" }
        return "\(days / 7) weeks ago"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mountain.2.fill")
                .foregroundColor(.sageGreen)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.mountainName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                Text("\(record.mountainElevation)m elevation")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.0f%%", record.confidenceScore))
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(confidenceColor.opacity(0.15))
                    .foregroundColor(confidenceColor)
                    .clipShape(Capsule())

                Text(relativeDate)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .lostGlassStyle()
    }
}

#Preview {
    StatsView()
        .environmentObject(AppState())
        .environmentObject(SettingsManager())
}
