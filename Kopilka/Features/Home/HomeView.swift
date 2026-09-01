import SwiftUI

/// Главный экран: общий баланс, список целей и быстрые пополнения.
struct HomeView: View {
    @Environment(SavingsStore.self) private var store

    @State private var isCreatingGoal = false
    @State private var quickAddGoal: Goal?
    @State private var celebratingPalette: GoalPalette?

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()

                ScrollView {
                    LazyVStack(spacing: Metrics.stackSpacing) {
                        if store.hasAnyGoals {
                            header
                            activeSection
                            completedSection
                            createButton
                        } else {
                            emptyState
                        }
                    }
                    .padding(.horizontal, Metrics.screenPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
                .scrollIndicators(.hidden)
            }
            .background(Theme.background)
            .navigationTitle("Копилка")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isCreatingGoal = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .accessibilityLabel("Новая цель")
                }
            }
            .navigationDestination(for: Goal.ID.self) { goalID in
                GoalDetailView(goalID: goalID)
            }
        }
        .sheet(isPresented: $isCreatingGoal) {
            GoalEditorView(mode: .create)
        }
        .sheet(item: $quickAddGoal) { goal in
            AmountEntrySheet(goalID: goal.id, kind: .deposit) { justCompleted, palette in
                if justCompleted { celebrate(palette) }
            }
        }
        .overlay {
            if let celebratingPalette {
                ConfettiView(palette: celebratingPalette)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Секции

    private var header: some View {
        BalanceHeaderCard(
            totalSaved: store.totalSaved,
            totalTarget: store.totalTarget,
            progress: store.overallProgress,
            currency: store.currency,
            monthDeposits: store.depositsThisMonth,
            streakWeeks: store.weeklyStreak()
        )
    }

    @ViewBuilder
    private var activeSection: some View {
        let goals = store.activeGoals
        if !goals.isEmpty {
            VStack(spacing: 12) {
                SectionHeader(
                    title: "Активные цели",
                    subtitle: "\(goals.count) \(Plural.goals(goals.count)) в работе"
                )
                ForEach(goals) { goal in
                    goalRow(goal)
                }
            }
            .padding(.top, 6)
        }
    }

    @ViewBuilder
    private var completedSection: some View {
        let goals = store.completedGoals
        if !goals.isEmpty {
            VStack(spacing: 12) {
                SectionHeader(
                    title: "Достигнуто",
                    subtitle: "\(goals.count) \(Plural.goals(goals.count)) закрыто"
                )
                ForEach(goals) { goal in
                    goalRow(goal)
                }
            }
            .padding(.top, 6)
        }
    }

    /// Карточка-ссылка и кнопка быстрого пополнения поверх неё.
    private func goalRow(_ goal: Goal) -> some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(value: goal.id) {
                GoalCardView(goal: goal, currency: store.currency)
            }
            .pressableCard()

            Button {
                quickAddGoal = goal
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(CircleIconButtonStyle(size: 38, tint: goal.palette.accentColor))
            .padding(.top, 22)
            .padding(.trailing, Metrics.cardPadding)
            .accessibilityLabel("Пополнить цель «\(goal.title)»")
        }
    }

    private var createButton: some View {
        Button {
            isCreatingGoal = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                Text("Новая цель")
            }
        }
        .buttonStyle(SecondaryButtonStyle(tint: Theme.textSecondary))
        .padding(.top, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            EmptyStateView(
                symbolName: "sparkles",
                title: "Пока нет целей",
                message: "Создайте первую: название, сумма и, если нужно, срок."
            ) {
                Button("Создать цель") {
                    isCreatingGoal = true
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: 320)
            }
            .cardStyle(padding: 20)
        }
        .padding(.top, 40)
    }

    // MARK: - Празднование

    private func celebrate(_ palette: GoalPalette) {
        withAnimation(.easeOut(duration: 0.2)) {
            celebratingPalette = palette
        }
        Task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation(.easeOut(duration: 0.4)) {
                celebratingPalette = nil
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(SampleData.store)
}
