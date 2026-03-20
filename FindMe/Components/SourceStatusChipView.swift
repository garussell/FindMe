import SwiftUI

struct SourceStatusChipView: View {
    let status: SourceFetchStatus

    private var label: String {
        switch status.state {
        case .live:
            "\(status.source.displayName) Live"
        case .sample:
            "\(status.source.displayName) Sample"
        case .empty:
            "\(status.source.displayName) Empty"
        }
    }

    private var color: Color {
        switch status.state {
        case .live:
            .green
        case .sample:
            .orange
        case .empty:
            .secondary
        }
    }

    private var icon: String {
        switch status.state {
        case .live: "antenna.radiowaves.left.and.right"
        case .sample: "doc.text"
        case .empty: "tray"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            HStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(label)
                    .font(.caption.weight(.semibold))
            }
            Text("\(status.resultCount) jobs")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(status.source.displayName): \(status.state.rawValue), \(status.resultCount) jobs")
    }
}
