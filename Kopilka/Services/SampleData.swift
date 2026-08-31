import Foundation

/// Демонстрационные данные: используются в превью Xcode и в пункте
/// «Загрузить пример» на пустом экране.
enum SampleData {
    private static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
    }

    private static func daysAhead(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now
    }

    static var goals: [Goal] {
        [
            Goal(
                title: "Отпуск в Японии",
                targetAmount: 420_000,
                symbolName: "airplane",
                palette: .ocean,
                deadline: daysAhead(180),
                note: "Токио, Киото и Осака весной",
                createdAt: daysAgo(120),
                transactions: [
                    Transaction(amount: 40_000, date: daysAgo(110), note: "Премия"),
                    Transaction(amount: 25_000, date: daysAgo(82)),
                    Transaction(amount: 30_000, date: daysAgo(54), note: "Отложил с зарплаты"),
                    Transaction(amount: 12_000, kind: .withdrawal, date: daysAgo(40), note: "Срочный ремонт"),
                    Transaction(amount: 35_000, date: daysAgo(21)),
                    Transaction(amount: 18_000, date: daysAgo(4))
                ]
            ),
            Goal(
                title: "Подушка безопасности",
                targetAmount: 600_000,
                symbolName: "cross.case.fill",
                palette: .forest,
                note: "Три месяца привычных расходов",
                createdAt: daysAgo(240),
                transactions: [
                    Transaction(amount: 90_000, date: daysAgo(200)),
                    Transaction(amount: 60_000, date: daysAgo(150)),
                    Transaction(amount: 75_000, date: daysAgo(96)),
                    Transaction(amount: 55_000, date: daysAgo(63)),
                    Transaction(amount: 48_000, date: daysAgo(30)),
                    Transaction(amount: 22_000, date: daysAgo(9))
                ]
            ),
            Goal(
                title: "MacBook Pro",
                targetAmount: 240_000,
                symbolName: "laptopcomputer",
                palette: .graphite,
                deadline: daysAhead(45),
                createdAt: daysAgo(70),
                transactions: [
                    Transaction(amount: 60_000, date: daysAgo(60)),
                    Transaction(amount: 45_000, date: daysAgo(32)),
                    Transaction(amount: 38_000, date: daysAgo(12))
                ]
            ),
            Goal(
                title: "Новый велосипед",
                targetAmount: 85_000,
                symbolName: "bicycle",
                palette: .sunset,
                createdAt: daysAgo(150),
                transactions: [
                    Transaction(amount: 35_000, date: daysAgo(140)),
                    Transaction(amount: 30_000, date: daysAgo(100)),
                    Transaction(amount: 20_000, date: daysAgo(66))
                ],
                completedAt: daysAgo(66)
            )
        ]
    }

    static var state: AppState {
        var settings = AppSettings.default
        settings.hasCompletedOnboarding = true
        return AppState(goals: goals, settings: settings)
    }

    static var store: SavingsStore {
        SavingsStore(previewState: state)
    }

    static var singleGoal: Goal { goals[0] }
}
