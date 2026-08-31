import SwiftUI

/// Экран статистики: сводка, динамика по месяцам и распределение по целям.
struct StatsView: View {
    @Environment(SavingsStore.self) private var store

    private var currency: CurrencyOption { store.currency }

    private var columns: [GridItem] {
        [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground(palette: .forest, intensity: 0.55)

                ScrollView {
                    VStack(spacing: Metrics.stackSpacing) {
                        if store.allTransactions.isEmpty {
                            EmptyStateView(
                                symbolName: "chart.bar.xaxis",
                                title: "Статистика появится позже",
                                message: "Сделайте первое пополнение — и здесь появятся динамика по месяцам, средний вклад и серия недель."
                            )
                            .cardStyle(padding: 20)
                            .padding(.top, 30)
                        } else {
                            tiles
                            MonthlyChartView(buckets: store.monthlyBuckets(), currency: currency)
                            distribution
                        }
                    }
                    .padding(.horizontal, Metrics.screenPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
                .scrollIndicators(.hidden)
            }
            .background(Theme.background)
            .navigationTitle("Статистика")
        }
    }

    private var tiles: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            StatTile(
                title: "Всего накоплено",
                value: store.totalSaved.formatted(currency: currency),
                symbolName: "banknote.fill",
                tint: Theme.accent
            )
            StatTile(
                title: "Пополнено в этом месяце",
                value: store.depositsThisMonth.formatted(currency: currency),
                symbolName: "calendar",
                tint: Theme.positive
            )
            StatTile(
                title: "Средний вклад",
                value: store.averageDeposit.formatted(currency: currency),
                symbolName: "chart.line.uptrend.xyaxis",
                tint: GoalPalette.ocean.accentColor
            )
            StatTile(
                title: "Недель подряд с пополнением",
                value: "\(store.weeklyStreak())",
                symbolName: "flame.fill",
                tint: GoalPalette.sunset.accentColor
            )
            StatTile(
                title: "Целей закрыто",
                value: "\(store.completedGoals.count)",
                symbolName: "checkmark.seal.fill",
                tint: GoalPalette.forest.accentColor
            )
            StatTile(
                title: "Всего пополнений",
                value: "\(store.depositCount)",
                symbolName: "arrow.down.left",
                tint: GoalPalette.orchid.accentColor
            )
        }
    }

    @ViewBuilder
    private var distribution: some View {
        let goals = store.visibleGoals.filter { $0.savedAmount > 0 }
        if !goals.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Распределение", subtitle: "Где лежат накопления")

                ForEach(goals) { goal in
                    VStack(spacing: 8) {
                        HStack(spacing: 10) {
                            IconBadge(symbolName: goal.symbolName, palette: goal.palette, size: 30, filled: false)

                            Text(goal.title)
                                .font(.bodyRegular)
                                .foregroundStyle(Theme.textPrimary)
                                .lineLimit(1)

                            Spacer(minLength: 8)

                            Text(share(of: goal))
                                .font(.rounded(14, weight: .bold))
                                .foregroundStyle(Theme.textSecondary)
                        }

                        ProgressBarView(
                            progress: shareRatio(of: goal),
                            palette: goal.palette,
                            height: 6
                        )
                    }
                    .padding(.vertical, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
    }

    private func shareRatio(of goal: Goal) -> Double {
        let total = store.totalSaved.doubleValue
        guard total > 0 else { return 0 }
        return goal.savedAmount.doubleValue / total
    }

    private func share(of goal: Goal) -> String {
        "\(Int((shareRatio(of: goal) * 100).rounded()))%"
    }
}

#Preview {
    StatsView()
        .environment(SampleData.store)
}
