import Foundation

struct CoastlineBearingService {
    private let session: URLSession
    private let timeout: TimeInterval

    init(session: URLSession = .shared, timeout: TimeInterval = 10) {
        self.session = session
        self.timeout = timeout
    }

    func detectBearing(lat: Double, lon: Double) async -> Double? {
        guard let url = buildQueryURL(lat: lat, lon: lon) else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = timeout

        guard let data = try? await session.data(for: request).0,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let elements = json["elements"] as? [[String: Any]] else {
            return nil
        }

        let ways = elements.filter { ($0["type"] as? String) == "way" }
        guard let closest = findClosestSegment(ways: ways, lat: lat, lon: lon) else { return nil }

        let segmentBearing = computeSegmentBearing(a: closest.a, b: closest.b)
        return CompassAngle.normalize(segmentBearing + 90)
    }

    private func buildQueryURL(lat: Double, lon: Double) -> URL? {
        var components = URLComponents(string: "https://overpass-api.de/api/interpreter")!
        let query = """
        [out:json][timeout:8];
        way(around:1000,\(lat),\(lon))["natural"="coastline"];
        (._;>;);
        out geom;
        """
        components.queryItems = [URLQueryItem(name: "data", value: query)]
        return components.url
    }

    private func findClosestSegment(ways: [[String: Any]], lat: Double, lon: Double) -> (a: (Double, Double), b: (Double, Double))? {
        var bestSegment: ((Double, Double), (Double, Double))?
        var bestDist = Double.greatestFiniteMagnitude

        for way in ways {
            guard let geometry = way["geometry"] as? [[String: Any]] else { continue }
            for i in 0..<(geometry.count - 1) {
                guard let aLat = geometry[i]["lat"] as? Double,
                      let aLon = geometry[i]["lon"] as? Double,
                      let bLat = geometry[i + 1]["lat"] as? Double,
                      let bLon = geometry[i + 1]["lon"] as? Double else { continue }
                let dist = pointToSegmentDistance(px: lon, py: lat,
                                                   ax: aLon, ay: aLat,
                                                   bx: bLon, by: bLat)
                if dist < bestDist {
                    bestDist = dist
                    bestSegment = ((aLat, aLon), (bLat, bLon))
                }
            }
        }

        return bestSegment.map { seg in
            (a: (seg.0.0, seg.0.1), b: (seg.1.0, seg.1.1))
        }
    }

    private func pointToSegmentDistance(px: Double, py: Double,
                                         ax: Double, ay: Double,
                                         bx: Double, by: Double) -> Double {
        let dx = bx - ax
        let dy = by - ay
        let lenSq = dx * dx + dy * dy
        if lenSq == 0 { return haversine(lat1: py, lon1: px, lat2: ay, lon2: ax) }

        var t = ((px - ax) * dx + (py - ay) * dy) / lenSq
        t = max(0, min(1, t))

        let projLon = ax + t * dx
        let projLat = ay + t * dy
        return haversine(lat1: py, lon1: px, lat2: projLat, lon2: projLon)
    }

    private func computeSegmentBearing(a: (Double, Double), b: (Double, Double)) -> Double {
        let dLon = (b.1 - a.1).radians
        let lat1 = a.0.radians
        let lat2 = b.0.radians
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x).degrees
        return CompassAngle.normalize(bearing)
    }

    private func haversine(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let r = 6_371_000.0
        let dLat = (lat2 - lat1).radians
        let dLon = (lon2 - lon1).radians
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1.radians) * cos(lat2.radians) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return r * c
    }
}

private extension Double {
    var radians: Double { self * .pi / 180 }
    var degrees: Double { self * 180 / .pi }
}