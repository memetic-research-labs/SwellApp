import Foundation

protocol SurfSpotLookup {
    func search(_ query: String) throws -> [SurfSpot]
    func getAll() -> [SurfSpot]
}

final class SurfSpotDatabase: SurfSpotLookup {
    private let spots: [SurfSpot]

    init() {
        guard let url = Bundle.main.url(forResource: "surf-spots", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([SurfSpot].self, from: data) else {
            self.spots = []
            return
        }
        self.spots = decoded
    }

    init(spots: [SurfSpot]) {
        self.spots = spots
    }

    func search(_ query: String) throws -> [SurfSpot] {
        guard query.count >= 2 else { return [] }
        let lowercased = query.lowercased()
        return spots.filter { spot in
            spot.name.lowercased().contains(lowercased) ||
            spot.region.lowercased().contains(lowercased)
        }
    }

    func getAll() -> [SurfSpot] {
        spots.sorted { $0.name < $1.name }
    }
}
