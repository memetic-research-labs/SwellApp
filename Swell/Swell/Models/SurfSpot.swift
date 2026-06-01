import Foundation

struct SurfSpot: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var region: String
    var country: String
    var latitude: Double
    var longitude: Double
    var bearing: Double
    var bottomType: String
    var difficulty: String

    func toBeach() -> Beach {
        Beach(name: name, latitude: latitude, longitude: longitude, bearing: bearing)
    }
}
