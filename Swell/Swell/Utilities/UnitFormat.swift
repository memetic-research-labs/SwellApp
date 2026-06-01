import Foundation

enum UnitFormat {

    static func swellHeight(_ meters: Double, unit: UnitSystem = .imperial) -> String {
        switch unit {
        case .imperial:
            let feet = meters * 3.28084
            if feet >= 1.0 {
                return "\(String(format: "%.0f", feet))ft"
            } else {
                return "\(String(format: "%.1f", feet))ft"
            }
        case .metric:
            return "\(String(format: "%.1f", meters))m"
        }
    }

    static func windSpeed(_ metersPerSecond: Double, unit: UnitSystem = .imperial) -> String {
        switch unit {
        case .imperial:
            let mph = metersPerSecond * 2.23694
            return "\(Int(mph.rounded()))mph"
        case .metric:
            return "\(String(format: "%.0f", metersPerSecond)) m/s"
        }
    }

    static func swellPeriod(_ seconds: Double) -> String {
        "\(Int(seconds.rounded()))s"
    }

    static func windLabel(for windScore: Double) -> String {
        if windScore > 0.6 { return "Offshore" }
        if windScore > 0.3 { return "Cross-shore" }
        return "Onshore"
    }

    static func windLabelShort(for windScore: Double) -> String {
        if windScore > 0.6 { return "offshore" }
        if windScore > 0.3 { return "cross" }
        return "onshore"
    }

    static func directionDegrees(_ degrees: Double) -> String {
        "\(Int(degrees.rounded()))°"
    }
}

enum UnitSystem: String, CaseIterable {
    case imperial
    case metric
}

extension UnitSystem {
    var label: String {
        switch self {
        case .imperial: return "Imperial (ft, mph)"
        case .metric: return "Metric (m, m/s)"
        }
    }

    var shortLabel: String {
        switch self {
        case .imperial: return "Imperial"
        case .metric: return "Metric"
        }
    }
}