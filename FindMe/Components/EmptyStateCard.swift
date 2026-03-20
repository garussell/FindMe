import SwiftUI

struct EmptyStateCard: View {
    let title: String
    let message: String
    let systemImage: String
    var suggestions: [String] = []
    var retryAction: (() -> Void)?

    @State private var appeared = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: systemImage)
                .font(.system(size: 44))
                .foregroundStyle(.blue.opacity(0.6))
                .symbolEffect(.pulse, options: .repeating)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Label(suggestion, systemImage: "lightbulb")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, Theme.Spacing.xxs)
            }

            if let retryAction {
                Button {
                    retryAction()
                } label: {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .padding(.top, Theme.Spacing.xxs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xxl)
        .cardStyle()
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .onAppear {
            withAnimation(Theme.Animation.smooth) {
                appeared = true
            }
        }
        .accessibilityElement(children: .combine)
    }
}
