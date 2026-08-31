import Foundation
import Observation

/// Единственный источник правды приложения: цели, операции и настройки.
/// Всё, что меняет состояние, проходит через этот класс и сразу уезжает на диск.
@Observable
final class SavingsStore {
    private(set) var goals: [Goal]

    var settings: AppSettings {
        didSet {
            guard settings != oldValue else { return }
            persist()
        }
    }

    @ObservationIgnored private let fileStore: StateFileStore
    @ObservationIgnored private let haptics: HapticsService

    init(fileStore: StateFileStore = .shared, haptics: HapticsService = .shared) {
        self.fileStore = fileStore
        self.haptics = haptics
        let state = fileStore.load()
        self.goals = state.goals
        self.settings = state.settings
    }

    /// Инициализатор для превью и демо-режима — без чтения диска.
    init(previewState state: AppState) {
        self.fileStore = .shared
        self.haptics = .shared
        self.goals = state.goals
        self.settings = state.settings
    }

    // MARK: - Выборки

    var currency: CurrencyOption { settings.currency }

    var activeGoals: [Goal] {
        goals.filter { !$0.isArchived && !$0.isCompleted }
    }

    var completedGoals: [Goal] {
        goals.filter { !$0.isArchived && $0.isCompleted }
    }

    var archivedGoals: [Goal] {
        goals.filter(\.isArchived)
    }

    var visibleGoals: [Goal] {
        activeGoals + completedGoals
    }

    var hasAnyGoals: Bool { !goals.isEmpty }

    func goal(id: Goal.ID) -> Goal? {
        goals.first { $0.id == id }
    }

    // MARK: - Итоги

    var totalSaved: Money {
        goals.filter { !$0.isArchived }.reduce(Money.zero) { $0 + $1.savedAmount }
    }

    var totalTarget: Money {
        goals.filter { !$0.isArchived }.reduce(Money.zero) { $0 + $1.targetAmount }
    }

    var totalRemaining: Money {
        max(totalTarget - totalSaved, 0)
    }

    var overallProgress: Double {
        guard totalTarget > 0 else { return 0 }
        return min(max(totalSaved.doubleValue / totalTarget.doubleValue, 0), 1)
    }

    var allTransactions: [Transaction] {
        goals.flatMap(\.transactions)
    }

    // MARK: - Цели

    func add(_ goal: Goal) {
        goals.append(goal)
        persist()
        haptics.play(.success, enabled: settings.hapticsEnabled)
    }

    func update(_ goal: Goal) {
        guard let index = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        var updated = goal
        // Цель могли «раскрыть» обратно, подняв сумму — тогда отметка о закрытии снимается.
        if !updated.isCompleted { updated.completedAt = nil }
        goals[index] = updated
        persist()
    }

    func delete(goalID: Goal.ID) {
        goals.removeAll { $0.id == goalID }
        persist()
        haptics.play(.warning, enabled: settings.hapticsEnabled)
    }

    func setArchived(_ archived: Bool, goalID: Goal.ID) {
        guard let index = goals.firstIndex(where: { $0.id == goalID }) else { return }
        goals[index].isArchived = archived
        persist()
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        goals.move(fromOffsets: source, toOffset: destination)
        persist()
    }

    // MARK: - Операции

    /// Добавляет операцию и сообщает, закрылась ли цель именно сейчас —
    /// по этому флагу экран запускает конфетти.
    @discardableResult
    func addTransaction(_ transaction: Transaction, to goalID: Goal.ID) -> Bool {
        guard let index = goals.firstIndex(where: { $0.id == goalID }) else { return false }
        let wasCompleted = goals[index].isCompleted
        goals[index].transactions.append(transaction)

        let justCompleted = !wasCompleted && goals[index].isCompleted
        if justCompleted {
            goals[index].completedAt = .now
        } else if !goals[index].isCompleted {
            goals[index].completedAt = nil
        }

        persist()
        haptics.play(justCompleted ? .success : .light, enabled: settings.hapticsEnabled)
        return justCompleted
    }

    func deleteTransaction(id: Transaction.ID, from goalID: Goal.ID) {
        guard let index = goals.firstIndex(where: { $0.id == goalID }) else { return }
        goals[index].transactions.removeAll { $0.id == id }
        if !goals[index].isCompleted { goals[index].completedAt = nil }
        persist()
    }

    // MARK: - Сброс

    func resetEverything() {
        goals = []
        settings = .default
        settings.hasCompletedOnboarding = true
        fileStore.reset()
        persist()
    }

    func loadDemoData() {
        goals = SampleData.goals
        persist()
    }

    // MARK: - Сохранение

    private func persist() {
        fileStore.save(AppState(goals: goals, settings: settings))
    }
}
