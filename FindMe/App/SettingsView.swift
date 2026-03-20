import SwiftUI

struct SettingsView: View {
    @Environment(AppContainer.self) private var container

    var body: some View {
        NavigationStack {
            List {
                Section {
                    configRow("Adzuna", ready: container.configuration.hasAdzunaCredentials)
                    configRow("JSearch", ready: container.configuration.hasJSearchCredentials)
                    configRow("USAJobs", ready: container.configuration.hasUSAJobsCredentials)
                    configRow("BLS", ready: container.configuration.blsAPIKey != nil, optional: true)
                    configRow("ArbeitNow", ready: true, note: "No key required")
                    configRow("Google Jobs", ready: container.configuration.hasSerpApiCredentials, note: "via SerpApi")
                } header: {
                    Text("API Configuration")
                } footer: {
                    Text("Add credentials in APIConfig.local.plist or environment variables to enable live data.")
                }

                Section("Location") {
                    HStack {
                        Label("Location Access", systemImage: "location")
                        Spacer()
                        switch container.locationManager.state {
                        case .resolved:
                            Text("Active")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.green)
                        case .denied:
                            Text("Denied")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.orange)
                        default:
                            Text("Not Set")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Config Keys") {
                    Group {
                        Text("ADZUNA_APP_ID")
                        Text("ADZUNA_APP_KEY")
                        Text("JSEARCH_API_KEY")
                        Text("USAJOBS_API_KEY")
                        Text("USAJOBS_USER_AGENT")
                        Text("BLS_API_KEY")
                        Text("SERPAPI_KEY")
                    }
                    .font(.footnote.monospaced())
                }
            }
            .navigationTitle("Settings")
        }
    }

    @ViewBuilder
    private func configRow(_ title: String, ready: Bool, optional: Bool = false, note: String? = nil) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                if let note {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if optional {
                    Text("Optional")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(ready ? "Ready" : "Sample Mode")
                .font(.caption.weight(.semibold))
                .foregroundStyle(ready ? .green : .orange)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(ready ? "ready" : "sample mode")")
    }
}
