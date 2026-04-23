import Foundation
import Combine

struct HourlyForecast: Identifiable {
    let id = UUID()
    let hour: String       // e.g. "9am"
    let temp: Int          // celsius
    let weatherCode: Int   // WMO weather code
    let windSpeed: Int     // km/h
    let precipitation: Double // mm
}

struct SummitForecast {
    let tempMin: Int
    let tempMax: Int
    let windSpeed: Int
    let visibility: Int    // km (estimated from weather code)
    let precipitationSum: Double
    let weatherCode: Int
    let hourly: [HourlyForecast]

    // Safety assessment
    var windSafe: Bool { windSpeed < 50 }
    var visibilitySafe: Bool { visibility >= 5 }
    var precipSafe: Bool { precipitationSum < 5.0 }
    var overallGo: Bool { windSafe && visibilitySafe && precipSafe }

    var weatherEmoji: String {
        switch weatherCode {
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
}

class HikeWeatherService: ObservableObject {
    @Published var forecast: SummitForecast?
    @Published var isLoading = false
    @Published var error: String?

    func fetchForecast(latitude: Double, longitude: Double, date: Date) {
        isLoading = true
        error = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&daily=temperature_2m_max,temperature_2m_min,windspeed_10m_max,precipitation_sum,weathercode&hourly=temperature_2m,weathercode,windspeed_10m,precipitation&timezone=auto&start_date=\(dateString)&end_date=\(dateString)"

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, err in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let err = err { self?.error = err.localizedDescription; return }
                guard let data = data else { return }

                do {
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        self?.error = "Invalid JSON response"
                        return
                    }
                    
                    let daily = json["daily"] as? [String: Any]
                    let hourly = json["hourly"] as? [String: Any]

                    let tempMax = (daily?["temperature_2m_max"] as? [Double])?.first
                    let tempMin = (daily?["temperature_2m_min"] as? [Double])?.first
                    let wind = (daily?["windspeed_10m_max"] as? [Double])?.first
                    let precip = (daily?["precipitation_sum"] as? [Double])?.first
                    let wCode = (daily?["weathercode"] as? [Int])?.first

                    // Parse hourly — take hours 6 to 18
                    var hourlyForecasts: [HourlyForecast] = []
                    if let times = hourly?["time"] as? [String],
                       let temps = hourly?["temperature_2m"] as? [Double],
                       let codes = hourly?["weathercode"] as? [Int],
                       let winds = hourly?["windspeed_10m"] as? [Double],
                       let precips = hourly?["precipitation"] as? [Double] {
                        
                        let isoFormatter = ISO8601DateFormatter()
                        isoFormatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
                        
                        for i in 0..<times.count {
                            // The API might return times in "YYYY-MM-DDTHH:MM" format which ISO8601DateFormatter handles if configured correctly or simple DateFormatter
                            let dateStr = times[i]
                            let hour: Int
                            if let date = isoFormatter.date(from: dateStr + ":00Z") { // Mocking Z for auto timezone
                                hour = Calendar.current.component(.hour, from: date)
                            } else {
                                // Fallback parsing for "2023-10-27T06:00"
                                let components = dateStr.components(separatedBy: "T")
                                if components.count == 2 {
                                    hour = Int(components[1].prefix(2)) ?? 0
                                } else {
                                    hour = 0
                                }
                            }
                            
                            if hour >= 6 && hour <= 18 {
                                let label = hour == 0 ? "12am" : hour < 12 ? "\(hour)am" : hour == 12 ? "12pm" : "\(hour-12)pm"
                                hourlyForecasts.append(HourlyForecast(
                                    hour: label,
                                    temp: Int(temps[i]),
                                    weatherCode: codes[i],
                                    windSpeed: Int(winds[i]),
                                    precipitation: precips[i]
                                ))
                            }
                        }
                    }

                    // Estimate visibility from weather code
                    let visKm: Int
                    switch wCode ?? 0 {
                    case 0: visKm = 20
                    case 1...3: visKm = 10
                    case 45...48: visKm = 2
                    case 51...99: visKm = 4
                    default: visKm = 8
                    }

                    self?.forecast = SummitForecast(
                        tempMin: Int(tempMin ?? -99),
                        tempMax: Int(tempMax ?? -99),
                        windSpeed: Int(wind ?? 0),
                        visibility: visKm,
                        precipitationSum: precip ?? 0,
                        weatherCode: wCode ?? 0,
                        hourly: hourlyForecasts
                    )
                } catch {
                    self?.error = "Failed to parse forecast"
                }
            }
        }.resume()
    }
}
