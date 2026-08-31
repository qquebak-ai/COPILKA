import Foundation

/// Одна операция по цели: пополнение или снятие.
struct Transaction: Identifiable, Codable, Hashable {
    enum Kind: String, Codable, Hashable {
        case deposit
        case withdrawal

        var title: String {
            switch self {
            case .deposit: return "Пополнение"
            case .withdrawal: return "Снятие"
            }
        }

        var symbolName: String {
            switch self {
            case .deposit: return "arrow.down.left"
            case .withdrawal: return "arrow.up.right"
            }
        }
    }

    var id: UUID
    var amount: Money
    var kind: Kind
    var date: Date
    var note: String

    init(id: UUID = UUID(), amount: Money, kind: Kind = .deposit, date: Date = .now, note: String = "") {
        self.id = id
        self.amount = amount.magnitude.roundedToCents
        self.kind = kind
        self.date = date
        self.note = note
    }

    /// Вклад операции в накопленную сумму: пополнение со знаком «плюс», снятие — «минус».
    var signedAmount: Money {
        kind == .deposit ? amount : -amount
    }
}
