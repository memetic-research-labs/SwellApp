import Foundation

struct WeatherForecast: Codable {
    struct HourlyData: Codable {
        var time: [String]
        var windDirection10m: [Double]
        var windSpeed10m: [Double]
    }

    var latitude: Double
    var longitude: Double
    var utcOffsetSeconds: Int
    var timezone: String
    var hourly: HourlyData

    init(latitude: Double, longitude: Double,
         utcOffsetSeconds: Int, timezone: String,
         hourly: HourlyData) {
        self.latitude = latitude
        self.longitude = longitude
        self.utcOffsetSeconds = utcOffsetSeconds
        self.timezone = timezone
        self.hourly = hourly
    }

    enum CodingKeys: String, CodingKey {
        case latitude, longitude, timezone
        case utcOffsetSeconds = "utc_offset_seconds"
        case hourly

        enum HourlyCodingKeys: String, CodingKey {
            case time
            case windDirection10m = "wind_direction_10m"
            case windSpeed10m = "wind_speed_10m"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        utcOffsetSeconds = try container.decode(Int.self, forKey: .utcOffsetSeconds)
        timezone = try container.decode(String.self, forKey: .timezone)

        let hourlyContainer = try container.nestedContainer(keyedBy: CodingKeys.HourlyCodingKeys.self, forKey: .hourly)
        hourly = HourlyData(
            time: try hourlyContainer.decode([String].self, forKey: .time),
            windDirection10m: try hourlyContainer.decode([Double].self, forKey: .windDirection10m),
            windSpeed10m: try hourlyContainer.decode([Double].self, forKey: .windSpeed10m)
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(utcOffsetSeconds, forKey: .utcOffsetSeconds)
        try container.encode(timezone, forKey: .timezone)

        var hourlyContainer = container.nestedContainer(keyedBy: CodingKeys.HourlyCodingKeys.self, forKey: .hourly)
        try hourlyContainer.encode(hourly.time, forKey: .time)
        try hourlyContainer.encode(hourly.windDirection10m, forKey: .windDirection10m)
        try hourlyContainer.encode(hourly.windSpeed10m, forKey: .windSpeed10m)
    }
}
