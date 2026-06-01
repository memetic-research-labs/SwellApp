import SwiftUI
import Charts

@MainActor
@Observable
final class ForecastViewModel {
    private let service: OpenMeteoService
    private let engine: SurfQualityEngine
    var hourlyScores: [HourlySurfScore] = []
    var isLoading = true
    var errorMessage: String?

    init(service: OpenMeteoService = OpenMeteoService(),
         engine: SurfQualityEngine = SurfQualityEngine()) {
        self.service = service
        self.engine = engine
    }

    func load(for beach: Beach) async {
        isLoading = true
        errorMessage = nil
        do {
            let combined = try await service.fetchCombinedForecast(lat: beach.latitude, lon: beach.longitude)
            hourlyScores = engine.score(beach: beach, marine: combined.marine, weather: combined.weather)
        } catch {
            errorMessage = error.localizedDescription
            hourlyScores = []
        }
        isLoading = false
    }

    var bestScore: HourlySurfScore? {
        hourlyScores.max(by: { $0.starRating < $1.starRating })
    }
}

struct ForecastView: View {
    let beach: Beach
    @State private var viewModel = ForecastViewModel()
    @AppStorage("unitSystem") private var unitSystem = "imperial"
    private var unit: UnitSystem { UnitSystem(rawValue: unitSystem) ?? .imperial }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading forecast...")
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(
                    "Couldn't load forecast",
                    systemImage: "antenna.radiowaves.left.and.right.slash",
                    description: Text(error)
                )
            } else if viewModel.hourlyScores.isEmpty {
                ContentUnavailableView(
                    "No data available",
                    systemImage: "water.waves"
                )
            } else {
                mainContent
            }
        }
        .navigationTitle(beach.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .task { await viewModel.load(for: beach) }
        .refreshable { await viewModel.load(for: beach) }
    }

    var mainContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let current = viewModel.hourlyScores.first {
                    heroCard(for: current)
                }
                chartSection
                hourlySection
            }
            .padding(.bottom, 24)
        }
    }

    func heroCard(for score: HourlySurfScore) -> some View {
        VStack(spacing: 6) {
            HStack(alignment: .lastTextBaseline) {
                Text(UnitFormat.swellHeight(score.swellHeight, unit: unit))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                StarsView(rating: score.starRating)
                    .font(.title2)
                Spacer()
            }

            ShorelineConditionView(
                beachBearing: beach.bearing,
                swellDirection: score.swellDirection,
                swellHeight: score.swellHeight,
                windDirection: score.windDirection,
                windScore: score.windScore
            )
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    var chartSection: some View {
        let preview = Array(viewModel.hourlyScores.prefix(72))

        return VStack(alignment: .leading, spacing: 4) {
            Text("Forecast")
                .font(.headline)
                .padding(.horizontal)

            Chart(preview) { score in
                LineMark(
                    x: .value("Time", score.time),
                    y: .value("Stars", score.starRating)
                )
                .interpolationMethod(.cardinal)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .foregroundStyle(.blue)

                AreaMark(
                    x: .value("Time", score.time),
                    y: .value("Stars", score.starRating)
                )
                .interpolationMethod(.cardinal)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.15), .blue.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisValueLabel(format: .dateTime.hour())
                }
            }
            .chartYScale(domain: 0...5)
            .chartYAxis(.hidden)
            .frame(height: 100)
            .padding(.horizontal, 8)
        }
    }

    var hourlySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Today")
                .font(.headline)
                .padding(.horizontal)
                .padding(.bottom, 6)

            ForEach(viewModel.hourlyScores.prefix(24)) { score in
                CompactRow(score: score, unit: unit)
                Divider().padding(.leading, 48)
            }
        }
    }
}

struct CompactRow: View {
    let score: HourlySurfScore
    let unit: UnitSystem

    var body: some View {
        HStack(spacing: 8) {
            Text(timeDisplay)
                .font(.caption).bold()
                .frame(width: 42, alignment: .leading)

            starBadge

            Text(UnitFormat.swellHeight(score.swellHeight, unit: unit))
                .font(.subheadline).bold().monospacedDigit()

            Text(UnitFormat.windSpeed(score.windSpeed, unit: unit))
                .font(.caption).monospacedDigit()
                .foregroundStyle(.secondary)

            windBadge

            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    var starBadge: some View {
        Text("\(score.starRating)★")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(starColor)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(starColor.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    var windBadge: some View {
        Text(UnitFormat.windLabelShort(for: score.windScore))
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(CompactRow.windColor(score.windScore))
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(CompactRow.windColor(score.windScore).opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    var starColor: Color {
        switch score.starRating {
        case 4...5: return .green
        case 3: return .yellow
        default: return .red
        }
    }

    static func windColor(_ windScore: Double) -> Color {
        if windScore > 0.6 { return .green }
        if windScore > 0.3 { return .yellow }
        return .red
    }

    var timeDisplay: String {
        let parts = score.time.components(separatedBy: "T")
        if parts.count == 2 { return String(parts[1].prefix(5)) }
        return score.time
    }
}