import SwiftUI

struct SettingsView: View {
    @AppStorage("unitSystem") private var unitSystem = "imperial"

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Units", selection: $unitSystem) {
                        ForEach(UnitSystem.allCases, id: \.rawValue) { unit in
                            Text(unit.label).tag(unit.rawValue)
                        }
                    }
                } header: {
                    Text("Display")
                }

                Section {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Platform", value: "iOS 18+")
                } header: {
                    Text("About")
                }

                Section {
                    Text("Forecast data provided by Open-Meteo.com. Wave and weather models from NOAA, ECMWF, DWD, and Météo-France.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Data Sources")
                }

                Section {
                    Text("Swell is free and open source. No subscription, no tracking. All data is sourced from free public weather APIs.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Privacy")
                }
            }
            .navigationTitle("Settings")
        }
    }
}