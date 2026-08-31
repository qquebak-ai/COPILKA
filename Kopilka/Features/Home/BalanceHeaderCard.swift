import SwiftUI

/// Главная карточка: сколько всего накоплено и как это выглядит на фоне целей.
struct BalanceHeaderCard: View {
    var totalSaved: Money
    var totalTarget: Money
    var progress: Double
    var currency: CurrencyOption
    var monthDeposits: Money
    var streakWeeks: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Всего накоплено")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)

                    AnimatedMoneyText(amount: totalSaved, currency: currency, font: .displayLarge)

                    if totalTarget > 0 {
                        Text("из \(totalTarget.formatted(currency: currency))")
                            .font(.bodyRegular)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }

                Spacer(minLength: 12)

                ZStack {
                    ProgressRing(progress: progress, palette: .gold, lineWidth: 9)
                        .frame(width: 76, height: 76)
                    Text("\(Int((progress * 100).rounded(.down)))%")
                        .font(.rounded(15, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                }
            }

            Divider()
                .overlay(Theme.hairline)

            HStack(spacing: 10) {
                metric(
                    title: "В этом месяце",
                    value: monthDeposits > 0 ? "+" + monthDeposits.formatted(currency: currency) : "—",
                    symbolName: "calendar",
                    tint: Theme.positive
                )

                metric(
                    title: "Недель подряд",
                    value: streakWeeks > 0 ? "\(streakWeeks) \(Plural.weeks(streakWeeks))" : "—",
                    symbolName: "flame.fill",
                    tint: Theme.accent
                )
            }
        }
        .cardStyle(padding: 20)
    }

    private func metric(title: String, value: String, symbolName: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbolName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(Circle().fill(tint.opacity(0.13)))

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.rounded(14, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(title)
                    .font(.captionSmall)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    BalanceHeaderCard(
        totalSaved: 318_000,
        totalTarget: 1_345_000,
        progress: 0.31,
        currency: .ruble,
        monthDeposits: 40_000,
        streakWeeks: 3
    )
    .padding()
    .background(Theme.background)
}
