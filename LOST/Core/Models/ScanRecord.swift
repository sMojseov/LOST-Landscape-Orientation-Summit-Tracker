import Foundation

struct ScanRecord: Codable, Identifiable {
    let id: UUID
    let mountainName: String
    let mountainElevation: Int
    let date: Date
    let confidenceScore: Double
    let userLatitude: Double
    let userLongitude: Double

    init(mountainName: String, mountainElevation: Int, date: Date,
         confidenceScore: Double, userLatitude: Double, userLongitude: Double) {
        self.id = UUID()
        self.mountainName = mountainName
        self.mountainElevation = mountainElevation
        self.date = date
        self.confidenceScore = confidenceScore
        self.userLatitude = userLatitude
        self.userLongitude = userLongitude
    }

    static func save(_ record: ScanRecord) {
        var records = loadAll()
        records.insert(record, at: 0)
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: "scan_records")
        }
    }

    static func loadAll() -> [ScanRecord] {
        guard let data = UserDefaults.standard.data(forKey: "scan_records"),
              let records = try? JSONDecoder().decode([ScanRecord].self, from: data) else {
            return []
        }
        return records
    }
}
