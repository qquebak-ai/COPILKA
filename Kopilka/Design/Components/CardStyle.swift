import SwiftUI

/// Карточка приложения: полупрозрачная поверхность, тонкий кант и мягкая тень.
struct CardStyle: ViewModifier {
    var padding: CGFloat = Metrics.cardPadding
    var radius: CGFloat = Metrics.cardRadius
    var strokeOpacity: Double = 1

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Theme.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(Theme.hairline.opacity(strokeOpacity), lineWidth: 1)
                    }
                    .shadow(color: Theme.shadow.opacity(0.10), radius: 22, x: 0, y: 12)
                    .shadow(color: Theme.shadow.opacity(0.05), radius: 3, x: 0, y: 1)
            }
    }
}

extension View {
    func cardStyle(
        padding: CGFloat = Metrics.cardPadding,
        radius: CGFloat = Metrics.cardRadius,
        strokeOpacity: Double = 1
    ) -> some View {
        modifier(CardStyle(padding: padding, radius: radius, strokeOpacity: strokeOpacity))
    }

    /// Аккуратное «дыхание» при нажатии — используется у карточек-ссылок.
    func pressableCard() -> some View {
        buttonStyle(PressableCardButtonStyle())
    }
}

struct PressableCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.32, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
