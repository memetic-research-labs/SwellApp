import Foundation

struct HourlySurfScore: Identifiable, Hashable {
    var id: String { time }

    var time: String
    var swellScore: Double
    var windScore: Double
    var sizeScore: Double
    var periodScore: Double
    var compositeScore: Double
    var starRating: Int
    var swellHeight: Double
    var swellPeriod: Double
    var swellDirection: Double
    var windSpeed: Double
    var windDirection: Double
}

extension HourlySurfScore {
    var qualityLabel: String {
        switch starRating {
        case 1: "Very Poor"
        case 2: "Poor"
        case 3: "Fair"
        case 4: "Good"
        case 5: "Excellent"
        default: "Unknown"
        }
    }
}
