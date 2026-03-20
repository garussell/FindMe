import Observation
import SwiftUI

// MARK: - Toast Model

struct Toast: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let icon: String
    let tint: Color

    static func saved(_ title: String) -> Toast {
        Toast(message: "Saved \(title)", icon: "bookmark.fill", tint: .blue)
    }

    static func removed(_ title: String) -> Toast {
        Toast(message: "Removed \(title)", icon: "bookmark.slash", tint: .secondary)
    }

    static func error(_ message: String) -> Toast {
        Toast(message: message, icon: "exclamationmark.triangle.fill", tint: .red)
    }

    static func success(_ message: String) -> Toast {
        Toast(message: message, icon: "checkmark.circle.fill", tint: .green)
    }
}

// MARK: - Toast Manager

@MainActor
@Observable
final class ToastManager {
    var current: Toast?
    private var dismissTask: Task<Void, Never>?

    func show(_ toast: Toast) {
        dismissTask?.cancel()
        withAnimation(Theme.Animation.snappy) {
            current = toast
        }
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            withAnimation(Theme.Animation.snappy) {
                current = nil
            }
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        withAnimation(Theme.Animation.snappy) {
            current = nil
        }
    }
}

// MARK: - Toast Overlay View

struct ToastOverlay: View {
    let toast: Toast?

    var body: some View {
        VStack {
            if let toast {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: toast.icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(toast.tint)

                    Text(toast.message)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.md)
                .background(.ultraThinMaterial, in: Capsule())
                .shadow(
                    color: Theme.Shadow.card.color,
                    radius: Theme.Shadow.card.radius,
                    x: Theme.Shadow.card.x,
                    y: Theme.Shadow.card.y
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer()
        }
        .padding(.top, Theme.Spacing.sm)
        .animation(Theme.Animation.springy, value: toast?.id)
    }
}
