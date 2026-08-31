import Foundation

/// Пользовательские настройки. Живут рядом с целями в одном файле состояния.
struct AppSettings: Codable, Hashable {
    enum AppearanceOption: String, Codable, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }

        var title: String {
            switch self {
            case .system: return "Как в системе"
            case .light: return "Светлая"
            case .dark: return "Тёмная"
            }
        }

        var symbolName: String {
            switch self {
            case .system: return "iphone"
            case .light: return "sun.max.fill"
            case .dark: return "moon.stars.fill"
            }
        }
    }

    var currencyCode: String
    var appearance: AppearanceOption
    var hapticsEnabled: Bool
    var reminderEnabled: Bool
    /// Час напоминания в 24-часовом формате.
    var reminderHour: Int
    var reminderWeekday: Int
    var hasCompletedOnboarding: Bool

    var currency: CurrencyOption {
        CurrencyOption.option(for: currencyCode)
    }

    static let `default` = AppSettings(
        currencyCode: CurrencyOption.deviceDefault.code,
        appearance: .system,
        hapticsEnabled: true,
        reminderEnabled: false,
        reminderHour: 19,
        reminderWeekday: 1,
        hasCompletedOnboarding: false
    )
}

/// Снимок всего состояния приложения — то, что уходит на диск.
struct AppState: Codable {
    var goals: [Goal]
    var settings: AppSettings

    static let empty = AppState(goals: [], settings: .default)
}
