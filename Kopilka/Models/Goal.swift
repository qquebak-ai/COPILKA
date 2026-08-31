import Foundation

/// Цель накопления — центральная сущность приложения.
struct Goal: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var targetAmount: Money
    var symbolName: String
    var palette: GoalPalette
    var deadline: Date?
    var note: String
    var createdAt: Date
    var transactions: [Transaction]
    var isArchived: Bool
    /// Момент, когда цель впервые была закрыта. Нужен, чтобы не показывать
    /// конфетти дважды и чтобы считать статистику достижений.
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        targetAmount: Money,
        symbolName: String = GoalSymbol.defaultSymbol,
        palette: GoalPalette = .gold,
        deadline: Date? = nil,
        note: String = "",
        createdAt: Date = .now,
        transactions: [Transaction] = [],
        isArchived: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.targetAmount = max(targetAmount, 0).roundedToCents
        self.symbolName = symbolName
        self.palette = palette
        self.deadline = deadline
        self.note = note
        self.createdAt = createdAt
        self.transactions = transactions
        self.isArchived = isArchived
        self.completedAt = completedAt
    }
}

// MARK: - Производные значения

extension Goal {
    /// Накоплено: пополнения минус снятия, но не меньше нуля.
    var savedAmount: Money {
        let total = transactions.reduce(Money.zero) { $0 + $1.signedAmount }
        return max(total, 0).roundedToCents
    }

    var remainingAmount: Money {
        max(targetAmount - savedAmount, 0).roundedToCents
    }

    /// 0…1 — используется кольцами и полосами прогресса.
    var progress: Double {
        guard targetAmount > 0 else { return savedAmount > 0 ? 1 : 0 }
        let ratio = savedAmount.doubleValue / targetAmount.doubleValue
        return min(max(ratio, 0), 1)
    }

    var progressPercentString: String {
        "\(Int((progress * 100).rounded(.down)))%"
    }

    var isCompleted: Bool {
        targetAmount > 0 && savedAmount >= targetAmount
    }

    var sortedTransactions: [Transaction] {
        transactions.sorted { $0.date > $1.date }
    }

    var lastActivityDate: Date? {
        transactions.map(\.date).max()
    }

    /// Сколько дней осталось до дедлайна (nil, если срок не задан).
    var daysLeft: Int? {
        guard let deadline else { return nil }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.startOfDay(for: deadline)
        return calendar.dateComponents([.day], from: start, to: end).day
    }

    var isOverdue: Bool {
        guard let daysLeft, !isCompleted else { return false }
        return daysLeft < 0
    }

    /// Сколько нужно откладывать в день, чтобы успеть к сроку.
    var dailyPace: Money? {
        guard let daysLeft, daysLeft > 0, !isCompleted, remainingAmount > 0 else { return nil }
        return (remainingAmount / Money(daysLeft)).roundedToCents
    }

    /// То же самое, но неделями — так цифра выглядит человечнее.
    var weeklyPace: Money? {
        guard let daily = dailyPace else { return nil }
        return (daily * 7).roundedToCents
    }

    var deadlineDescription: String? {
        guard let deadline else { return nil }
        let formatted = deadline.formatted(.dateTime.day().month(.wide).year())
        guard let daysLeft else { return formatted }
        if isCompleted { return "Цель закрыта" }
        switch daysLeft {
        case ..<0: return "Просрочено на \(abs(daysLeft)) \(Plural.days(abs(daysLeft)))"
        case 0: return "Последний день"
        default: return "Осталось \(daysLeft) \(Plural.days(daysLeft))"
        }
    }
}

// MARK: - Наборы иконок

enum GoalSymbol {
    static let defaultSymbol = "target"

    /// SF Symbols, которые точно есть в iOS 17 и хорошо смотрятся в кружке.
    static let all: [String] = [
        "target", "house.fill", "car.fill", "airplane", "beach.umbrella.fill",
        "graduationcap.fill", "gift.fill", "heart.fill", "gamecontroller.fill",
        "laptopcomputer", "iphone", "camera.fill", "headphones", "bicycle",
        "pawprint.fill", "cross.case.fill", "cup.and.saucer.fill", "fork.knife",
        "book.fill", "tent.fill", "ticket.fill", "wrench.and.screwdriver.fill",
        "bag.fill", "shippingbox.fill", "sparkles", "crown.fill",
        "banknote.fill", "creditcard.fill", "chart.line.uptrend.xyaxis", "leaf.fill"
    ]
}

// MARK: - Склонения

enum Plural {
    /// «1 день», «2 дня», «5 дней» — без этого интерфейс сразу выглядит дёшево.
    static func form(_ count: Int, one: String, few: String, many: String) -> String {
        let absolute = abs(count) % 100
        let lastDigit = absolute % 10
        if absolute > 10 && absolute < 20 { return many }
        if lastDigit == 1 { return one }
        if (2...4).contains(lastDigit) { return few }
        return many
    }

    static func days(_ count: Int) -> String {
        form(count, one: "день", few: "дня", many: "дней")
    }

    static func goals(_ count: Int) -> String {
        form(count, one: "цель", few: "цели", many: "целей")
    }

    static func operations(_ count: Int) -> String {
        form(count, one: "операция", few: "операции", many: "операций")
    }

    static func weeks(_ count: Int) -> String {
        form(count, one: "неделя", few: "недели", many: "недель")
    }
}
