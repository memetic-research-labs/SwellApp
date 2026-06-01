import Foundation

protocol MarineForecastFetching: Sendable {
    func fetchForecast(lat: Double, lon: Double) async throws -> MarineForecast
}

protocol WeatherForecastFetching: Sendable {
    func fetchForecast(lat: Double, lon: Double) async throws -> WeatherForecast
}

protocol CombinedForecastFetching: Sendable {
    func fetchCombinedForecast(lat: Double, lon: Double) async throws -> CombinedForecast
}

struct CombinedForecast {
    var marine: MarineForecast
    var weather: WeatherForecast
}

enum OpenMeteoServiceError: Error, Equatable {
    case invalidURL
    case networkError(String)
    case decodingError(String)
    case serverError(Int)
}

actor OpenMeteoService: MarineForecastFetching, WeatherForecastFetching, CombinedForecastFetching {
    private let fetchData: @Sendable (URL) async throws -> (Data, URLResponse)

    init() {
        self.fetchData = { url in
            try await URLSession.shared.data(from: url)
        }
    }

    init(fetchData: @escaping @Sendable (URL) async throws -> (Data, URLResponse)) {
        self.fetchData = fetchData
    }

    func fetchMarineForecast(lat: Double, lon: Double) async throws -> MarineForecast {
        var components = URLComponents(string: "https://marine-api.open-meteo.com/v1/marine")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(lat)),
            URLQueryItem(name: "longitude", value: String(lon)),
            URLQueryItem(name: "hourly", value: "wave_height,wave_direction,swell_wave_height,swell_wave_direction,swell_wave_period,wind_wave_height,wind_wave_direction"),
            URLQueryItem(name: "forecast_days", value: "7"),
            URLQueryItem(name: "length_unit", value: "metric")
        ]
        guard let url = components.url else { throw OpenMeteoServiceError.invalidURL }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await fetchData(url)
        } catch {
            throw OpenMeteoServiceError.networkError(error.localizedDescription)
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenMeteoServiceError.serverError(-1)
        }
        if httpResponse.statusCode >= 400 {
            throw OpenMeteoServiceError.serverError(httpResponse.statusCode)
        }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(MarineForecast.self, from: data)
        } catch {
            throw OpenMeteoServiceError.decodingError(error.localizedDescription)
        }
    }

    func fetchWeatherForecast(lat: Double, lon: Double) async throws -> WeatherForecast {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(lat)),
            URLQueryItem(name: "longitude", value: String(lon)),
            URLQueryItem(name: "hourly", value: "wind_direction_10m,wind_speed_10m"),
            URLQueryItem(name: "forecast_days", value: "7"),
            URLQueryItem(name: "wind_speed_unit", value: "ms")
        ]
        guard let url = components.url else { throw OpenMeteoServiceError.invalidURL }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await fetchData(url)
        } catch {
            throw OpenMeteoServiceError.networkError(error.localizedDescription)
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenMeteoServiceError.serverError(-1)
        }
        if httpResponse.statusCode >= 400 {
            throw OpenMeteoServiceError.serverError(httpResponse.statusCode)
        }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(WeatherForecast.self, from: data)
        } catch {
            throw OpenMeteoServiceError.decodingError(error.localizedDescription)
        }
    }

    func fetchCombinedForecast(lat: Double, lon: Double) async throws -> CombinedForecast {
        async let marine = fetchMarineForecast(lat: lat, lon: lon)
        async let weather = fetchWeatherForecast(lat: lat, lon: lon)
        return try await CombinedForecast(marine: marine, weather: weather)
    }

    func fetchForecast(lat: Double, lon: Double) async throws -> MarineForecast {
        try await fetchMarineForecast(lat: lat, lon: lon)
    }

    func fetchForecast(lat: Double, lon: Double) async throws -> WeatherForecast {
        try await fetchWeatherForecast(lat: lat, lon: lon)
    }
}
