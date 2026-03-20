import SwiftUI

/// Design system constants for consistent spacing, typography, and styling.
/// Based on an 8pt grid system with a cohesive color palette.
enum Theme {
    // MARK: - Spacing (8pt grid)

    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 6
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        static let huge: CGFloat = 40
        static let massive: CGFloat = 48
    }

    // MARK: - Corner Radii

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let pill: CGFloat = 100
    }

    // MARK: - Shadows

    enum Shadow {
        static let card = ShadowStyle(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        static let cardHover = ShadowStyle(color: .black.opacity(0.10), radius: 20, x: 0, y: 8)
        static let subtle = ShadowStyle(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    // MARK: - Colors

    enum Colors {
        static let primaryGradientStart = Color.blue
        static let primaryGradientEnd = Color.cyan
        static let cardBackground = Color(.systemBackground)
        static let surfaceSecondary = Color(.secondarySystemBackground)

        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red

        static let newBadge = Color.green
        static let hotBadge = Color.orange
    }

    // MARK: - Animations

    enum Animation {
        static let snappy = SwiftUI.Animation.snappy(duration: 0.3)
        static let smooth = SwiftUI.Animation.smooth(duration: 0.4)
        static let springy = SwiftUI.Animation.spring(duration: 0.5, bounce: 0.3)
        static let quick = SwiftUI.Animation.easeOut(duration: 0.2)
    }
}

// MARK: - Card Style Modifier

struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = Theme.Radius.xxl

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(
                        color: Theme.Shadow.card.color,
                        radius: Theme.Shadow.card.radius,
                        x: Theme.Shadow.card.x,
                        y: Theme.Shadow.card.y
                    )
            )
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = Theme.Radius.xxl) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius))
    }
}
