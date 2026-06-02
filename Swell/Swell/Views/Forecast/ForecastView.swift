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
            VStack(spacing: 12) {
                if let current = viewModel.hourlyScores.first {
                    heroCard(for: current)
                }
                chartSection
                hourlySection
            }
            .padding(12)
        }
    }

    func heroCard(for score: HourlySurfScore) -> some View {
        VStack(spacing: 8) {
            HStack(alignment: .lastTextBaseline) {
                Text(UnitFormat.swellHeight(score.swellHeight, unit: unit))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                StarsView(rating: score.starRating)
                    .font(.title2)
                Spacer()
                Text(score.qualityLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(qualityColor(score.starRating))
            }

            ShorelineConditionView(
                beachBearing: beach.bearing,
                swellDirection: score.swellDirection,
                swellHeight: score.swellHeight,
                windDirection: score.windDirection,
                windScore: score.windScore
            )
            .frame(maxWidth: .infinity)

            HStack(spacing: 12) {
                Spacer()
                conditionChip(
                    icon: "wind",
                    label: windLabel(for: score.windScore),
                    color: .purple
                )
                conditionChip(
                    icon: "stopwatch",
                    label: "\(UnitFormat.swellPeriod(score.swellPeriod))",
                    color: .secondary
                )
                conditionChip(
                    icon: "water.waves",
                    label: swellDirectionLabel(score.swellDirection),
                    color: .blue
                )
                Spacer()
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func conditionChip(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    var chartSection: some View {
        let preview = Array(viewModel.hourlyScores.prefix(72))

        return VStack(alignment: .leading, spacing: 8) {
            Text("Forecast")
                .font(.headline)

            Chart(preview) { score in
                BarMark(
                    x: .value("Time", score.time),
                    y: .value("Stars", score.starRating)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [qualityColor(score.starRating).opacity(0.6), qualityColor(score.starRating).opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                RuleMark(y: .value("Excellent", 4.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(.green.opacity(0.5))
                    .annotation(position: .trailing, alignment: .trailing) {
                        Text("5★")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.green.opacity(0.6))
                    }

                RuleMark(y: .value("OK", 2.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(.yellow.opacity(0.4))
                    .annotation(position: .trailing, alignment: .trailing) {
                        Text("3★")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.yellow.opacity(0.6))
                    }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { value in
                    AxisValueLabel(format: .dateTime.hour())
                }
            }
            .chartYScale(domain: 0...5)
            .chartYAxis(.hidden)
            .frame(height: 140)
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    var hourlySection: some View {
        let scores = Array(viewModel.hourlyScores.prefix(24))

        return VStack(alignment: .leading, spacing: 0) {
            let columns: [GridItem] = [
                GridItem(.fixed(3), spacing: 0),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
            ]

            Text("Today")
                .font(.headline)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)

            Divider()

            LazyVGrid(columns: columns, spacing: 0) {
                Color.clear.frame(width: 3)
                Text("Time")
                Text("Stars")
                Text("Swell")
                Text("Wind")
                Text("")
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            Divider()

            ForEach(scores) { score in
                LazyVGrid(columns: columns, spacing: 0) {
                    Rectangle()
                        .fill(qualityBarColor(score.starRating))
                        .frame(width: 3)

                    Text(timeDisplay(for: score))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("\(score.starRating)★")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(starColor(score.starRating))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(UnitFormat.swellHeight(score.swellHeight, unit: unit))
                        .font(.system(size: 14, weight: .bold, design: .rounded).monospacedDigit())
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(UnitFormat.windSpeed(score.windSpeed, unit: unit))
                        .font(.system(size: 13).monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    windBadgeView(score: score)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func timeDisplay(for score: HourlySurfScore) -> String {
        let parts = score.time.components(separatedBy: "T")
        if parts.count == 2 { return String(parts[1].prefix(5)) }
        return score.time
    }

    private func starColor(_ starRating: Int) -> Color {
        switch starRating {
        case 4...5: return .green
        case 3: return .yellow
        default: return .red
        }
    }

    private func qualityBarColor(_ starRating: Int) -> Color {
        switch starRating {
        case 4...5: return .green.opacity(0.7)
        case 3: return .yellow.opacity(0.7)
        default: return .red.opacity(0.5)
        }
    }

    private func windBadgeColor(_ windScore: Double) -> Color {
        if windScore > 0.6 { return .green }
        if windScore > 0.3 { return .yellow }
        return .red
    }

    private func windBadgeView(score: HourlySurfScore) -> some View {
        Text(UnitFormat.windLabelShort(for: score.windScore))
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(windBadgeColor(score.windScore))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(windBadgeColor(score.windScore).opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    private func qualityColor(_ stars: Int) -> Color {
        switch stars {
        case 4...5: return .green
        case 3: return .yellow
        default: return .red
        }
    }

    private func swellDirectionLabel(_ direction: Double) -> String {
        let rel = CompassAngle.normalize(direction - beach.bearing)
        if rel < 20 || rel > 340 { return "straight in" }
        if rel < 60 { return "from right" }
        if rel > 300 { return "from left" }
        return "angled"
    }

    private func windLabel(for windScore: Double) -> String {
        if windScore > 0.6 { return "Offshore" }
        if windScore > 0.3 { return "Cross-shore" }
        return "Onshore"
    }

}