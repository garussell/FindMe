import SwiftUI
import Observation

struct SearchFiltersCard: View {
    @Bindable var viewModel: JobSearchViewModel
    @Environment(AppContainer.self) private var container
    @FocusState private var salaryFocused: Bool
    @FocusState private var keywordFocused: Bool
    @FocusState private var locationFocused: Bool
    @State private var showFilters = false

    private var salaryBinding: Binding<String> {
        Binding(
            get: { viewModel.request.salaryMinimum.map(String.init) ?? "" },
            set: { newValue in
                viewModel.request.salaryMinimum = Int(newValue)
            }
        )
    }

    /// Number of non-default filters currently active.
    private var activeFilterCount: Int {
        var count = 0
        if viewModel.request.sourceFilter != .all { count += 1 }
        if viewModel.request.employmentType != .any { count += 1 }
        if viewModel.request.remoteOnly { count += 1 }
        if viewModel.request.salaryMinimum != nil { count += 1 }
        return count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // MARK: - Header
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Find Your Next Role")
                    .font(.title2.bold())

                Text("Search across Adzuna, JSearch, USAJobs, and ArbeitNow in one pass.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // MARK: - Keyword Field
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text("What")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                TextField("Job title, keyword, or company", text: $viewModel.request.keyword)
                    .textFieldStyle(.roundedBorder)
                    .focused($keywordFocused)
                    .submitLabel(.search)
                    .accessibilityLabel("Search keyword")
            }

            // MARK: - Location Field with Geolocation
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text("Where")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                HStack(spacing: Theme.Spacing.sm) {
                    TextField("City, state, or remote", text: $viewModel.request.location)
                        .textFieldStyle(.roundedBorder)
                        .focused($locationFocused)
                        .submitLabel(.search)
                        .accessibilityLabel("Search location")

                    locationButton
                }
            }

            // MARK: - Filter Toggle
            Button {
                withAnimation(Theme.Animation.snappy) {
                    showFilters.toggle()
                }
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Label("Filters", systemImage: "slider.horizontal.3")
                        .font(.subheadline.weight(.medium))

                    if activeFilterCount > 0 {
                        Text("\(activeFilterCount)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue, in: Capsule())
                    }

                    Spacer()

                    Image(systemName: showFilters ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Toggle filters, \(activeFilterCount) active")

            // MARK: - Collapsible Filters
            if showFilters {
                VStack(spacing: Theme.Spacing.md) {
                    HStack(spacing: Theme.Spacing.md) {
                        Picker("Source", selection: $viewModel.request.sourceFilter) {
                            ForEach(JobSourceFilter.allCases) { filter in
                                Text(filter.displayName).tag(filter)
                            }
                        }

                        Picker("Schedule", selection: $viewModel.request.employmentType) {
                            ForEach(EmploymentTypeFilter.allCases) { filter in
                                Text(filter.displayName).tag(filter)
                            }
                        }
                    }
                    .pickerStyle(.menu)

                    HStack(spacing: Theme.Spacing.md) {
                        Toggle("Remote only", isOn: $viewModel.request.remoteOnly)
                            .toggleStyle(.switch)

                        TextField("Salary min", text: salaryBinding)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .focused($salaryFocused)
                            .accessibilityLabel("Minimum salary")
                    }

                    if activeFilterCount > 0 {
                        Button {
                            withAnimation(Theme.Animation.snappy) {
                                viewModel.request.sourceFilter = .all
                                viewModel.request.employmentType = .any
                                viewModel.request.remoteOnly = false
                                viewModel.request.salaryMinimum = nil
                            }
                        } label: {
                            Label("Clear all filters", systemImage: "xmark.circle")
                                .font(.subheadline)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Theme.Spacing.xl)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.14), Color.cyan.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: Theme.Radius.xxl, style: .continuous)
        )
    }

    // MARK: - Location Button

    /// Shows different states: idle (offer location), loading, resolved (with clear), denied/failed (hidden).
    @ViewBuilder
    private var locationButton: some View {
        let locationState = container.locationManager.state

        switch locationState {
        case .idle, .failed:
            Button {
                Task {
                    await container.locationManager.requestLocation()
                    if let location = container.locationManager.resolvedLocation {
                        viewModel.request.location = location
                    }
                }
            } label: {
                Image(systemName: "location.fill")
                    .font(.body)
                    .foregroundStyle(.blue)
                    .frame(width: 36, height: 36)
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Use my location")

        case .requesting, .locating:
            ProgressView()
                .frame(width: 36, height: 36)
                .accessibilityLabel("Detecting location")

        case .resolved(let location):
            Button {
                viewModel.request.location = ""
                container.locationManager.clearLocation()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                    Image(systemName: "xmark")
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(.blue)
                .frame(width: 36, height: 36)
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Clear detected location: \(location)")

        case .denied:
            EmptyView()
        }
    }
}
