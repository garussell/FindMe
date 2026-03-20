import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppContainer.self) private var container

    var body: some View {
        ZStack {
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

            ToastOverlay(toast: container.toastManager.current)
                .allowsHitTesting(false)
        }
    }
}

#Preview {
    ContentView()
        .environment(AppContainer.makeLive())
        .modelContainer(for: SavedJob.self, inMemory: true)
}
