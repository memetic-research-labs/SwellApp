import Foundation

struct MarineForecast: Codable {
    struct HourlyData: Codable {
        var time: [String]
        var waveHeight: [Double]
        var waveDirection: [Double]
        var swellWaveHeight: [Double]
        var swellWaveDirection: [Double]
        var swellWavePeriod: [Double]
        var windWaveHeight: [Double]
        var windWaveDirection: [Double]
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
            case waveHeight = "wave_height"
            case waveDirection = "wave_direction"
            case swellWaveHeight = "swell_wave_height"
            case swellWaveDirection = "swell_wave_direction"
            case swellWavePeriod = "swell_wave_period"
            case windWaveHeight = "wind_wave_height"
            case windWaveDirection = "wind_wave_direction"
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
            waveHeight: try hourlyContainer.decode([Double].self, forKey: .waveHeight),
            waveDirection: try hourlyContainer.decode([Double].self, forKey: .waveDirection),
            swellWaveHeight: try hourlyContainer.decode([Double].self, forKey: .swellWaveHeight),
            swellWaveDirection: try hourlyContainer.decode([Double].self, forKey: .swellWaveDirection),
            swellWavePeriod: try hourlyContainer.decode([Double].self, forKey: .swellWavePeriod),
            windWaveHeight: try hourlyContainer.decode([Double].self, forKey: .windWaveHeight),
            windWaveDirection: try hourlyContainer.decode([Double].self, forKey: .windWaveDirection)
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
        try hourlyContainer.encode(hourly.waveHeight, forKey: .waveHeight)
        try hourlyContainer.encode(hourly.waveDirection, forKey: .waveDirection)
        try hourlyContainer.encode(hourly.swellWaveHeight, forKey: .swellWaveHeight)
        try hourlyContainer.encode(hourly.swellWaveDirection, forKey: .swellWaveDirection)
        try hourlyContainer.encode(hourly.swellWavePeriod, forKey: .swellWavePeriod)
        try hourlyContainer.encode(hourly.windWaveHeight, forKey: .windWaveHeight)
        try hourlyContainer.encode(hourly.windWaveDirection, forKey: .windWaveDirection)
    }
}
