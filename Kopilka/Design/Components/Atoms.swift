import SwiftUI

/// Иконка цели в скруглённом квадрате с градиентом.
struct IconBadge: View {
    var symbolName: String
    var palette: GoalPalette
    var size: CGFloat = 44
    var filled: Bool = true

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
            .fill(filled ? AnyShapeStyle(palette.gradient) : AnyShapeStyle(palette.tint))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: symbolName)
                    .font(.system(size: size * 0.44, weight: .semibold))
                    .foregroundStyle(filled ? Color.white : palette.accentColor)
            }
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                    .strokeBorder(Color.white.opacity(filled ? 0.25 : 0), lineWidth: 1)
            }
            .shadow(color: palette.accentColor.opacity(filled ? 0.35 : 0), radius: 10, y: 5)
    }
}

/// Заголовок секции с необязательной кнопкой справа.
struct SectionHeader<Trailing: View>: View {
    var title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.titleMedium)
                    .foregroundStyle(Theme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer(minLength: 12)
            trailing()
        }
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle, trailing: { EmptyView() })
    }
}

/// Плитка с одним числом — из таких собран экран статистики.
struct StatTile: View {
    var title: String
    var value: String
    var symbolName: String
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbolName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(Circle().fill(tint.opacity(0.14)))

            Text(value)
                .font(.rounded(20, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 16, radius: 22)
    }
}

/// Небольшой чип-подпись: срок, статус, темп накоплений.
struct InfoChip: View {
    var text: String
    var symbolName: String?
    var tint: Color = Theme.textSecondary

    var body: some View {
        HStack(spacing: 5) {
            if let symbolName {
                Image(systemName: symbolName)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(text)
                .font(.captionSmall)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(tint.opacity(0.12)))
    }
}

/// Сумма с плавной перекруткой цифр при изменении.
struct AnimatedMoneyText: View {
    var amount: Money
    var currency: CurrencyOption
    var font: Font = .displayMedium
    var color: Color = Theme.textPrimary

    var body: some View {
        Text(amount.formatted(currency: currency))
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: amount.doubleValue))
            .animation(.snappy(duration: 0.45), value: amount)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }
}

/// Пустое состояние с иконкой, текстом и действием.
struct EmptyStateView<Action: View>: View {
    var symbolName: String
    var title: String
    var message: String
    @ViewBuilder var action: () -> Action

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.accentSoft)
                    .frame(width: 96, height: 96)
                Image(systemName: symbolName)
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(Theme.accent)
            }
            .padding(.bottom, 4)

            Text(title)
                .font(.titleMedium)
                .foregroundStyle(Theme.textPrimary)

            Text(message)
                .font(.bodyRegular)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            action()
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
    }
}

extension EmptyStateView where Action == EmptyView {
    init(symbolName: String, title: String, message: String) {
        self.init(symbolName: symbolName, title: title, message: message, action: { EmptyView() })
    }
}
