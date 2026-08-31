import SwiftUI

/// Карточка цели в списке на главном экране.
struct GoalCardView: View {
    var goal: Goal
    var currency: CurrencyOption
    /// Место под кнопку быстрого пополнения. Сама кнопка живёт выше по иерархии:
    /// вложенные кнопки внутри NavigationLink перехватываются ссылкой.
    var reservesQuickAddSlot: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                IconBadge(symbolName: goal.symbolName, palette: goal.palette, size: 46)

                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.titleMedium)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        if goal.isCompleted {
                            InfoChip(text: "Цель достигнута", symbolName: "checkmark.seal.fill", tint: Theme.positive)
                        } else if let description = goal.deadlineDescription {
                            InfoChip(
                                text: description,
                                symbolName: "calendar",
                                tint: goal.isOverdue ? Theme.negative : Theme.textSecondary
                            )
                        } else if let weekly = goal.weeklyPace {
                            InfoChip(
                                text: "\(weekly.formatted(currency: currency)) в неделю",
                                symbolName: "bolt.fill",
                                tint: Theme.textSecondary
                            )
                        }
                    }
                }

                Spacer(minLength: 4)

                if reservesQuickAddSlot {
                    Color.clear.frame(width: 38, height: 38)
                }
            }

            VStack(spacing: 8) {
                ProgressBarView(progress: goal.progress, palette: goal.palette)

                HStack(alignment: .firstTextBaseline) {
                    Text(goal.savedAmount.formatted(currency: currency))
                        .font(.rounded(18, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText(value: goal.savedAmount.doubleValue))

                    Text("/ \(goal.targetAmount.formatted(currency: currency))")
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)

                    Spacer(minLength: 8)

                    Text(goal.progressPercentString)
                        .font(.rounded(14, weight: .bold))
                        .foregroundStyle(goal.palette.accentColor)
                }
            }
        }
        .cardStyle()
        .overlay(alignment: .topTrailing) {
            if goal.isCompleted {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(goal.palette.accentColor)
                    .padding(12)
            }
        }
        .animation(.snappy(duration: 0.4), value: goal.savedAmount)
    }
}

#Preview {
    VStack(spacing: 16) {
        GoalCardView(goal: SampleData.goals[0], currency: .ruble)
        GoalCardView(goal: SampleData.goals[3], currency: .ruble)
    }
    .padding()
    .background(Theme.background)
}
