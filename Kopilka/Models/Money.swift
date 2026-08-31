import Foundation

/// Денежная сумма приложения. Отдельный тип, чтобы форматирование
/// и округление жили в одном месте, а не расползались по вьюхам.
typealias Money = Decimal

extension Money {
    var isPositive: Bool { self > 0 }

    /// Округление до копеек «вниз» — чтобы прогресс не показывал 100 % раньше времени.
    var roundedToCents: Money {
        var source = self
        var result = Money()
        NSDecimalRound(&result, &source, 2, .plain)
        return result
    }

    var doubleValue: Double { NSDecimalNumber(decimal: self).doubleValue }
}

extension Money {
    /// «1 250 ₽» — основной формат для карточек и заголовков.
    func formatted(currency: CurrencyOption, showsFraction: Bool = false) -> String {
        let style = Decimal.FormatStyle.Currency(code: currency.code)
            .precision(.fractionLength(showsFraction ? 2 : 0))
            .rounded(rule: .down)
        return self.formatted(style)
    }

    /// «+1 250 ₽» / «−1 250 ₽» для истории операций.
    func formattedSigned(currency: CurrencyOption, positive: Bool) -> String {
        let sign = positive ? "+" : "−"
        return sign + magnitude.formatted(currency: currency)
    }

    /// Компактная запись для графиков: 12,5 тыс.
    var compactString: String {
        let value = doubleValue
        let absolute = abs(value)
        let formatter: (Double, String) -> String = { number, suffix in
            let rounded = (number * 10).rounded() / 10
            let text = rounded == rounded.rounded()
                ? String(format: "%.0f", rounded)
                : String(format: "%.1f", rounded).replacingOccurrences(of: ".", with: ",")
            return text + suffix
        }
        switch absolute {
        case 1_000_000...: return formatter(value / 1_000_000, " млн")
        case 1_000...: return formatter(value / 1_000, " тыс.")
        default: return String(format: "%.0f", value)
        }
    }
}
