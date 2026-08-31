import Foundation

/// Валюты, доступные в настройках. Держим короткий понятный список
/// вместо полного справочника ISO — так экран настроек остаётся живым.
struct CurrencyOption: Identifiable, Hashable, Codable {
    var code: String
    var symbol: String
    var title: String

    var id: String { code }

    static let ruble = CurrencyOption(code: "RUB", symbol: "₽", title: "Российский рубль")
    static let dollar = CurrencyOption(code: "USD", symbol: "$", title: "Доллар США")
    static let euro = CurrencyOption(code: "EUR", symbol: "€", title: "Евро")
    static let tenge = CurrencyOption(code: "KZT", symbol: "₸", title: "Казахстанский тенге")
    static let dirham = CurrencyOption(code: "AED", symbol: "د.إ", title: "Дирхам ОАЭ")
    static let lari = CurrencyOption(code: "GEL", symbol: "₾", title: "Грузинский лари")

    static let all: [CurrencyOption] = [.ruble, .dollar, .euro, .tenge, .dirham, .lari]

    /// Валюта по региону устройства, если мы её поддерживаем.
    static var deviceDefault: CurrencyOption {
        let code = Locale.current.currency?.identifier ?? "RUB"
        return all.first { $0.code == code } ?? .ruble
    }

    static func option(for code: String) -> CurrencyOption {
        all.first { $0.code == code } ?? .ruble
    }
}
