import SwiftUI

@MainActor
@Observable
final class SavedBeachesViewModel {
    private let store: BeachStoring
    private let service: OpenMeteoService
    private let engine: SurfQualityEngine
    var beaches: [Beach] = []
    var currentScores: [Beach.ID: HourlySurfScore] = {
        [:]
    }()

    init(store: BeachStoring = FileBeachStore(),
         service: OpenMeteoService = OpenMeteoService(),
         engine: SurfQualityEngine = SurfQualityEngine()) {
        self.store = store
        self.service = service
        self.engine = engine
    }

    func load() async {
        do {
            beaches = try await store.fetchAll()
            for beach in beaches {
                await loadScore(for: beach)
            }
        } catch {}
    }

    func delete(_ beach: Beach) async {
        do {
            try await store.delete(beach.id)
            beaches.removeAll { $0.id == beach.id }
        } catch {}
    }

    private func loadScore(for beach: Beach) async {
        do {
            let combined = try await service.fetchCombinedForecast(lat: beach.latitude, lon: beach.longitude)
            let scores = engine.score(beach: beach, marine: combined.marine, weather: combined.weather)
            if let first = scores.first {
                currentScores[beach.id] = first
            }
        } catch {}
    }

    func score(for beach: Beach) -> HourlySurfScore? {
        currentScores[beach.id]
    }
}

struct SavedBeachesView: View {
    @State private var viewModel = SavedBeachesViewModel()
    @Binding var path: NavigationPath
    @AppStorage("unitSystem") private var unitSystem = "imperial"

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if viewModel.beaches.isEmpty {
                    emptyState
                } else {
                    beachList
                }
            }
            .navigationTitle("Swell")
            .navigationDestination(for: Beach.self) { beach in
                ForecastView(beach: beach)
            }
            .onAppear { Task { await viewModel.load() } }
            .refreshable { await viewModel.load() }
        }
    }

    var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "water.waves")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("No spots saved")
                .font(.title2).bold()
            Text("Tap the Add tab to save your\nfavorite surf breaks")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    var beachList: some View {
        List {
            ForEach(viewModel.beaches) { beach in
                NavigationLink(value: beach) {
                    BeachRowView(
                        beach: beach,
                        score: viewModel.score(for: beach)
                    )
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let beach = viewModel.beaches[index]
                    Task { await viewModel.delete(beach) }
                }
            }
        }
    }
}

struct BeachRowView: View {
    let beach: Beach
    let score: HourlySurfScore?

    @AppStorage("unitSystem") private var unitSystem = "imperial"
    private var unit: UnitSystem { UnitSystem(rawValue: unitSystem) ?? .imperial }

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(beach.name)
                    .font(.headline)
                if let score {
                    Text("\(UnitFormat.windLabel(for: score.windScore)) · \(UnitFormat.swellPeriod(score.swellPeriod))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let score {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(UnitFormat.swellHeight(score.swellHeight, unit: unit))
                        .font(.title3).bold().monospacedDigit()
                    StarsView(rating: score.starRating)
                }
            } else {
                ProgressView()
            }
        }
        .padding(.vertical, 6)
    }
}