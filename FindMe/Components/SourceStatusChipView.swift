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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
            Text("\(status.resultCount) jobs")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
    }
}
