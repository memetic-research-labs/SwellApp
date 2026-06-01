import Foundation

enum CompassAngle {
    static func normalize(_ degrees: Double) -> Double {
        var angle = degrees.truncatingRemainder(dividingBy: 360.0)
        if angle < 0 { angle += 360 }
        return angle
    }

    static func smallestDifference(_ a: Double, _ b: Double) -> Double {
        let diff = abs(normalize(a) - normalize(b))
        return min(diff, 360 - diff)
    }

    static func cosineSimilarity(_ a: Double, _ b: Double) -> Double {
        let radians = smallestDifference(a, b) * .pi / 180.0
        return cos(radians)
    }

    static func format(_ degrees: Double) -> String {
        let normalized = normalize(degrees)
        switch normalized {
        case 0..<22.5, 337.5..<360: return "N"
        case 22.5..<67.5: return "NE"
        case 67.5..<112.5: return "E"
        case 112.5..<157.5: return "SE"
        case 157.5..<202.5: return "S"
        case 202.5..<247.5: return "SW"
        case 247.5..<292.5: return "W"
        default: return "NW"
        }
    }

    static func add(_ base: Double, _ delta: Double) -> Double {
        normalize(base + delta)
    }

    static func subtract(_ base: Double, _ delta: Double) -> Double {
        normalize(base - delta)
    }
}
