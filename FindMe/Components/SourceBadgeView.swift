import SwiftUI

struct SourceBadgeView: View {
    let source: JobSource

    var body: some View {
        Label(source.displayName, systemImage: "dot.radiowaves.left.and.right")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(source.tint.opacity(0.15), in: Capsule())
            .foregroundStyle(source.tint)
    }
}

#Preview {
    SourceBadgeView(source: .adzuna)
}
