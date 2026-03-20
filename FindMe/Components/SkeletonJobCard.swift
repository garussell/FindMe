import SwiftUI

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.4),
                        .clear
                    ],
                    startPoint: .init(x: phase - 0.5, y: 0.5),
                    endPoint: .init(x: phase + 0.5, y: 0.5)
                )
                .blendMode(.overlay)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 2
                }
            }
            .accessibilityLabel("Loading")
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Job Card

struct SkeletonJobCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    // Title placeholder
                    skeletonRect(width: 200, height: 16)
                    // Company placeholder
                    skeletonRect(width: 140, height: 13)
                }
                Spacer()
                // Badge placeholder
                skeletonRect(width: 24, height: 24)
                    .clipShape(Circle())
            }

            HStack(spacing: 8) {
                skeletonRect(width: 70, height: 26)
                    .clipShape(Capsule())
                skeletonRect(width: 80, height: 26)
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 8) {
                skeletonRect(width: 180, height: 13)
                skeletonRect(width: 130, height: 13)
            }

            // Description placeholder
            VStack(alignment: .leading, spacing: 6) {
                skeletonRect(height: 12)
                skeletonRect(height: 12)
                skeletonRect(width: 220, height: 12)
            }

            skeletonRect(width: 90, height: 11)
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .shimmer()
    }

    private func skeletonRect(width: CGFloat? = nil, height: CGFloat = 14) -> some View {
        RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
            .fill(Color.primary.opacity(0.08))
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }
}

// MARK: - Skeleton Grid

struct SkeletonJobList: View {
    let count: Int

    var body: some View {
        LazyVStack(spacing: 14) {
            ForEach(0..<count, id: \.self) { index in
                SkeletonJobCard()
                    .opacity(1.0 - Double(index) * 0.15)
            }
        }
    }
}

#Preview {
    ScrollView {
        SkeletonJobList(count: 4)
            .padding()
    }
}
