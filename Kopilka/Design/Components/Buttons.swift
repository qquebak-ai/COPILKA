import SwiftUI

/// Главная кнопка: градиент, крупный радиус, отчётливое нажатие.
struct PrimaryButtonStyle: ButtonStyle {
    var gradient: LinearGradient = Theme.brandGradient
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bodyEmphasis)
            .foregroundStyle(Theme.textOnAccent)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background {
                RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                    .fill(gradient)
                    .overlay {
                        RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                            .strokeBorder(Theme.goldStroke, lineWidth: 1)
                    }
            }
            .opacity(isEnabled ? 1 : 0.4)
            .shadow(color: Theme.accent.opacity(isEnabled ? 0.35 : 0), radius: 16, x: 0, y: 8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Второстепенная кнопка: та же геометрия, но спокойная поверхность.
struct SecondaryButtonStyle: ButtonStyle {
    var tint: Color = Theme.textPrimary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bodyEmphasis)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background {
                RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                    .fill(Theme.surfaceSunken)
                    .overlay {
                        RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                            .strokeBorder(Theme.hairline, lineWidth: 1)
                    }
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Небольшая круглая кнопка-иконка для панелей навигации и карточек.
struct CircleIconButtonStyle: ButtonStyle {
    var size: CGFloat = 40
    var tint: Color = Theme.textPrimary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background {
                Circle()
                    .fill(Theme.surface)
                    .overlay { Circle().strokeBorder(Theme.hairline, lineWidth: 1) }
                    .shadow(color: Theme.shadow.opacity(0.12), radius: 8, y: 4)
            }
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.65), value: configuration.isPressed)
    }
}
