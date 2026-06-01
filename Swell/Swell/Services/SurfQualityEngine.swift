import Foundation

protocol SurfQualityScoring: Sendable {
    func score(beach: Beach, marine: MarineForecast, weather: WeatherForecast) -> [HourlySurfScore]
}

struct SurfQualityEngine: SurfQualityScoring {

    func score(beach: Beach, marine: MarineForecast, weather: WeatherForecast) -> [HourlySurfScore] {
        let count = min(
            marine.hourly.time.count,
            weather.hourly.time.count
        )
        guard count > 0 else { return [] }

        var scores: [HourlySurfScore] = []
        scores.reserveCapacity(count)

        for i in 0..<count {
            let swellDir = marine.hourly.swellWaveDirection[i]
            let swellHt = marine.hourly.swellWaveHeight[i]
            let swellPd = marine.hourly.swellWavePeriod[i]
            let windDir = weather.hourly.windDirection10m[i]
            let windSpd = weather.hourly.windSpeed10m[i]

            let swellScore = computeSwellScore(beachBearing: beach.bearing, swellDirection: swellDir, swellHeight: swellHt)
            let windScore = computeWindScore(beachBearing: beach.bearing, windDirection: windDir, windSpeed: windSpd)
            let sizeScore = computeSizeScore(swellHeight: swellHt)
            let periodScore = computePeriodScore(swellPeriod: swellPd)

            var composite = swellScore * 0.40 + windScore * 0.35 + sizeScore * 0.10 + periodScore * 0.15
            if swellScore == 0 {
                composite = composite * 0.25
            }
            let stars = max(1, min(5, Int((composite * 5).rounded())))

            scores.append(HourlySurfScore(
                time: marine.hourly.time[i],
                swellScore: swellScore,
                windScore: windScore,
                sizeScore: sizeScore,
                periodScore: periodScore,
                compositeScore: composite,
                starRating: stars,
                swellHeight: swellHt,
                swellPeriod: swellPd,
                swellDirection: swellDir,
                windSpeed: windSpd,
                windDirection: windDir
            ))
        }

        return scores
    }

    private func computeSwellScore(beachBearing: Double, swellDirection: Double, swellHeight: Double) -> Double {
        guard swellHeight > 0.05, !swellDirection.isNaN, !swellDirection.isInfinite else { return 0 }
        let similarity = CompassAngle.cosineSimilarity(swellDirection, beachBearing)
        return max(0, similarity)
    }

    private func computeWindScore(beachBearing: Double, windDirection: Double, windSpeed: Double) -> Double {
        guard !windDirection.isNaN, !windDirection.isInfinite else { return 0 }

        let offshoreBearing = CompassAngle.add(beachBearing, 180)
        let similarity = CompassAngle.cosineSimilarity(windDirection, offshoreBearing)
        let baseScore = max(0, similarity)

        let bonus: Double
        switch windSpeed {
        case 3.0...8.0:
            bonus = 0.15
        case 0..<3.0:
            bonus = 0.05
        case 8.0001...12.0:
            bonus = 0.0
        case 12.0001...:
            bonus = -0.1
        default:
            bonus = 0.0
        }

        return max(0, min(1, baseScore * (1 + bonus)))
    }

    private func computeSizeScore(swellHeight: Double) -> Double {
        switch swellHeight {
        case ..<0.1:
            return 0.0
        case 0.1..<0.5:
            return (swellHeight - 0.1) / 0.4 * 0.5
        case 0.5..<1.2:
            return 0.5 + (swellHeight - 0.5) / 0.7 * 0.5
        case 1.2..<2.0:
            return 1.0
        case 2.0..<4.0:
            return 1.0 - (swellHeight - 2.0) / 2.0 * 0.5
        default:
            return max(3.0 / swellHeight, 0.1)
        }
    }

    private func computePeriodScore(swellPeriod: Double) -> Double {
        guard !swellPeriod.isNaN, !swellPeriod.isInfinite else { return 0 }
        return 1.0 / (1.0 + exp(-(swellPeriod - 8.0) / 2.0))
    }
}
