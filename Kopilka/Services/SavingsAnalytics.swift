import Foundation

/// Точка на графике: один месяц и сумма пополнений в нём.
struct MonthlyBucket: Identifiable, Hashable {
    var id: Date { start }
    let start: Date
    let deposits: Money
    let withdrawals: Money

    var net: Money { deposits - withdrawals }

    var shortTitle: String {
        start.formatted(.dateTime.month(.abbreviated)).replacingOccurrences(of: ".", with: "")
    }

    var accessibleTitle: String {
        start.formatted(.dateTime.month(.wide).year())
    }
}

extension SavingsStore {
    /// Пополнения по месяцам за последние `count` месяцев, включая текущий.
    func monthlyBuckets(count: Int = 6, calendar: Calendar = .current) -> [MonthlyBucket] {
        let now = Date.now
        guard let thisMonth = calendar.dateInterval(of: .month, for: now)?.start else { return [] }

        let transactions = allTransactions
        return (0..<count).reversed().compactMap { offset -> MonthlyBucket? in
            guard let start = calendar.date(byAdding: .month, value: -offset, to: thisMonth),
                  let interval = calendar.dateInterval(of: .month, for: start) else { return nil }
            let inMonth = transactions.filter { interval.contains($0.date) }
            let deposits = inMonth.filter { $0.kind == .deposit }.reduce(Money.zero) { $0 + $1.amount }
            let withdrawals = inMonth.filter { $0.kind == .withdrawal }.reduce(Money.zero) { $0 + $1.amount }
            return MonthlyBucket(start: start, deposits: deposits, withdrawals: withdrawals)
        }
    }

    /// Сколько недель подряд (считая текущую) были пополнения.
    func weeklyStreak(calendar: Calendar = .current) -> Int {
        let deposits = allTransactions.filter { $0.kind == .deposit }
        guard !deposits.isEmpty else { return 0 }

        var weeks = Set<Date>()
        for transaction in deposits {
            if let start = calendar.dateInterval(of: .weekOfYear, for: transaction.date)?.start {
                weeks.insert(start)
            }
        }

        guard var cursor = calendar.dateInterval(of: .weekOfYear, for: .now)?.start else { return 0 }
        // Если на этой неделе ещё не пополняли, серия всё ещё жива —
        // начинаем отсчёт с прошлой недели.
        if !weeks.contains(cursor) {
            guard let previous = calendar.date(byAdding: .weekOfYear, value: -1, to: cursor) else { return 0 }
            cursor = previous
        }

        var streak = 0
        while weeks.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .weekOfYear, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    var depositsThisMonth: Money {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: .now) else { return .zero }
        return allTransactions
            .filter { $0.kind == .deposit && interval.contains($0.date) }
            .reduce(Money.zero) { $0 + $1.amount }
    }

    var bestMonth: MonthlyBucket? {
        monthlyBuckets(count: 12).max { $0.deposits < $1.deposits }.flatMap { $0.deposits > 0 ? $0 : nil }
    }

    var averageDeposit: Money {
        let deposits = allTransactions.filter { $0.kind == .deposit }
        guard !deposits.isEmpty else { return .zero }
        let total = deposits.reduce(Money.zero) { $0 + $1.amount }
        return (total / Money(deposits.count)).roundedToCents
    }

    var depositCount: Int {
        allTransactions.filter { $0.kind == .deposit }.count
    }

    /// Ближайшая к закрытию активная цель — её показываем в подсказке на главной.
    var closestGoal: Goal? {
        activeGoals
            .filter { $0.progress > 0 }
            .max { $0.progress < $1.progress }
    }
}
