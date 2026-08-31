import Foundation

/// Палитра цели. Хранится в модели как строка, а конкретные цвета
/// живут в слое дизайна — модель ничего не знает про SwiftUI.
enum GoalPalette: String, CaseIterable, Codable, Hashable, Identifiable {
    case gold
    case sunset
    case ocean
    case forest
    case orchid
    case graphite

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gold: return "Золото"
        case .sunset: return "Закат"
        case .ocean: return "Океан"
        case .forest: return "Лес"
        case .orchid: return "Орхидея"
        case .graphite: return "Графит"
        }
    }
}
