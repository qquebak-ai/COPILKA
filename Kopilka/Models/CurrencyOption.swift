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
    static let hryvnia = CurrencyOption(code: "UAH", symbol: "₴", title: "Украинская гривна")
    static let belarusianRuble = CurrencyOption(code: "BYN", symbol: "Br", title: "Белорусский рубль")
    static let lari = CurrencyOption(code: "GEL", symbol: "₾", title: "Грузинский лари")
    static let lira = CurrencyOption(code: "TRY", symbol: "₺", title: "Турецкая лира")
    static let dirham = CurrencyOption(code: "AED", symbol: "د.إ", title: "Дирхам ОАЭ")
    static let pound = CurrencyOption(code: "GBP", symbol: "£", title: "Фунт стерлингов")

    static let all: [CurrencyOption] = [
        .ruble, .dollar, .euro, .tenge, .hryvnia,
        .belarusianRuble, .lari, .lira, .dirham, .pound
    ]

    /// Валюта по региону устройства, если мы её поддерживаем.
    static var deviceDefault: CurrencyOption {
        let code = Locale.current.currency?.identifier ?? "RUB"
        return all.first { $0.code == code } ?? .ruble
    }

    static func option(for code: String) -> CurrencyOption {
        all.first { $0.code == code } ?? .ruble
    }
}
