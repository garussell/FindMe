import SwiftUI
import Observation

struct SearchFiltersCard: View {
    @Bindable var viewModel: JobSearchViewModel
    @FocusState private var salaryFocused: Bool

    private var salaryBinding: Binding<String> {
        Binding(
            get: { viewModel.request.salaryMinimum.map(String.init) ?? "" },
            set: { newValue in
                viewModel.request.salaryMinimum = Int(newValue)
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Search Across Public Job Sources")
                .font(.title2.bold())

            Text("Search multiple providers in one pass, keep federal and remote roles in the mix, and compare lightweight market context.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                TextField("Keyword or title", text: $viewModel.request.keyword)
                    .textFieldStyle(.roundedBorder)

                TextField("Location", text: $viewModel.request.location)
                    .textFieldStyle(.roundedBorder)

                HStack(spacing: 12) {
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

                HStack(spacing: 12) {
                    Toggle("Remote only", isOn: $viewModel.request.remoteOnly)
                        .toggleStyle(.switch)

                    TextField("Salary min", text: salaryBinding)
                        .textFieldStyle(.roundedBorder)
                        .focused($salaryFocused)
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.18), Color.cyan.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
    }
}
