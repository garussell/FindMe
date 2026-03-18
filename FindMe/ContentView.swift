import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            JobSearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            SavedJobsView()
                .tabItem {
                    Label("Saved", systemImage: "bookmark")
                }

            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppContainer.makeLive())
        .modelContainer(for: SavedJob.self, inMemory: true)
}
