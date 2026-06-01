import Foundation

struct Beach: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var bearing: Double

    init(id: UUID = UUID(),
         name: String,
         latitude: Double,
         longitude: Double,
         bearing: Double) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.bearing = bearing
    }
}
