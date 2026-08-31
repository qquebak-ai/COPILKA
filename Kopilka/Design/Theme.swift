import UIKit
import SwiftUI

// MARK: - Цвета из HEX

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(uiColor: UIColor(hex: hex, alpha: CGFloat(opacity)))
    }

    /// Цвет, который сам подстраивается под светлую и тёмную темы.
    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

// MARK: - Токены оформления

/// Единая палитра приложения. Все цвета — только отсюда,
/// поэтому тёмная тема получается бесплатно.
enum Theme {
    // Фон и поверхности
    static let background = Color.adaptive(light: 0xF4F1EC, dark: 0x0B0C10)
    static let backgroundDeep = Color.adaptive(light: 0xEBE6DE, dark: 0x06070A)
    static let surface = Color.adaptive(light: 0xFFFFFF, dark: 0x15171E)
    static let surfaceRaised = Color.adaptive(light: 0xFFFFFF, dark: 0x1C1F28)
    static let surfaceSunken = Color.adaptive(light: 0xF0EDE7, dark: 0x101219)

    // Текст
    static let textPrimary = Color.adaptive(light: 0x141518, dark: 0xF6F5F3)
    static let textSecondary = Color.adaptive(light: 0x6B6A67, dark: 0x9C9EA8)
    static let textTertiary = Color.adaptive(light: 0x9B9992, dark: 0x6C6F7A)
    static let textOnAccent = Color.adaptive(light: 0x1A1508, dark: 0x120F06)

    // Акценты
    static let accent = Color.adaptive(light: 0xC28A2E, dark: 0xF0C070)
    static let accentSoft = Color.adaptive(light: 0xF6E7C8, dark: 0x33291A)
    static let positive = Color.adaptive(light: 0x2E9464, dark: 0x54D19B)
    static let negative = Color.adaptive(light: 0xC0503F, dark: 0xF08A78)

    // Линии и тени
    static let hairline = Color.adaptive(light: 0xE2DDD3, dark: 0x2A2E39)
    static let shadow = Color.adaptive(light: 0x8A7F6B, dark: 0x000000)

    /// Фирменный градиент — золото с тёплым переходом.
    static let brandGradient = LinearGradient(
        colors: [Color(hex: 0xF7D486), Color(hex: 0xE0A64C), Color(hex: 0xC77E3A)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldStroke = LinearGradient(
        colors: [Color.white.opacity(0.45), Color.white.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Метрики

enum Metrics {
    static let cardRadius: CGFloat = 26
    static let smallRadius: CGFloat = 16
    static let controlRadius: CGFloat = 18
    static let screenPadding: CGFloat = 20
    static let cardPadding: CGFloat = 18
    static let stackSpacing: CGFloat = 16
}

// MARK: - Градиенты целей

extension GoalPalette {
    var colors: [Color] {
        switch self {
        case .gold: return [Color(hex: 0xF9D689), Color(hex: 0xD79A3F)]
        case .sunset: return [Color(hex: 0xFF9A76), Color(hex: 0xE05C6E)]
        case .ocean: return [Color(hex: 0x76C8F0), Color(hex: 0x3B6FD4)]
        case .forest: return [Color(hex: 0x8FD6A0), Color(hex: 0x2E8B6B)]
        case .orchid: return [Color(hex: 0xC9A7F5), Color(hex: 0x7A55C8)]
        case .graphite: return [Color(hex: 0x9AA3B2), Color(hex: 0x3D4552)]
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// Кольцевой градиент для прогресса: конический смотрится дороже линейного.
    var ringGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: colors + [colors[0]]),
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }

    var accentColor: Color { colors[1] }
    var highlightColor: Color { colors[0] }

    /// Мягкая заливка под иконки и чипы.
    var tint: Color { colors[1].opacity(0.14) }
}

// MARK: - Типографика

extension Font {
    /// Скруглённый шрифт — базовая гарнитура интерфейса.
    static func rounded(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static let displayLarge = Font.rounded(42, weight: .bold)
    static let displayMedium = Font.rounded(32, weight: .bold)
    static let titleLarge = Font.rounded(24, weight: .bold)
    static let titleMedium = Font.rounded(19, weight: .semibold)
    static let bodyEmphasis = Font.rounded(16, weight: .semibold)
    static let bodyRegular = Font.rounded(15, weight: .medium)
    static let caption = Font.rounded(13, weight: .medium)
    static let captionSmall = Font.rounded(11, weight: .semibold)
}
