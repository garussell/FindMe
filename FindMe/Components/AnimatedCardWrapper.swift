import SwiftUI

/// Wraps content with a staggered fade+slide entrance animation.
/// Respects `prefers-reduced-motion` via `accessibilityReduceMotion`.
struct AnimatedCardWrapper<Content: View>: View {
    let index: Int
    let content: Content
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(index: Int, @ViewBuilder content: () -> Content) {
        self.index = index
        self.content = content()
    }

    var body: some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : (reduceMotion ? 0 : 16))
            .onAppear {
                if reduceMotion {
                    appeared = true
                } else {
                    let delay = Double(index) * 0.06
                    withAnimation(Theme.Animation.smooth.delay(delay)) {
                        appeared = true
                    }
                }
            }
    }
}
