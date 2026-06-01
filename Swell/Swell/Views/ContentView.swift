import SwiftUI

struct ContentView: View {
    @State private var navigationPath = NavigationPath()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            SavedBeachesView(path: $navigationPath)
                .tabItem {
                    Label("Beaches", systemImage: "water.waves")
                }
                .tag(0)

            AddBeachView { beach in
                navigationPath.append(beach)
                selectedTab = 0
            }
            .tabItem {
                Label("Add", systemImage: "plus.circle")
            }
            .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(2)
        }
    }
}