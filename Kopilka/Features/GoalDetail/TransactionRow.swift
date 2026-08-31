import SwiftUI

/// Строка истории операций.
struct TransactionRow: View {
    var transaction: Transaction
    var currency: CurrencyOption
    var palette: GoalPalette

    private var isDeposit: Bool { transaction.kind == .deposit }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: transaction.kind.symbolName)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isDeposit ? Theme.positive : Theme.negative)
                .frame(width: 38, height: 38)
                .background {
                    Circle().fill((isDeposit ? Theme.positive : Theme.negative).opacity(0.12))
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.note.isEmpty ? transaction.kind.title : transaction.note)
                    .font(.bodyEmphasis)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                Text(transaction.date.formatted(.dateTime.day().month(.abbreviated).hour().minute()))
                    .font(.captionSmall)
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer(minLength: 8)

            Text(transaction.amount.formattedSigned(currency: currency, positive: isDeposit))
                .font(.rounded(15, weight: .bold))
                .foregroundStyle(isDeposit ? Theme.positive : Theme.negative)
        }
        .padding(.vertical, 8)
    }
}

/// Шкала вех: 25 %, 50 %, 75 %, 100 %.
struct MilestoneStrip: View {
    var progress: Double
    var palette: GoalPalette

    private let milestones: [Double] = [0.25, 0.5, 0.75, 1.0]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(milestones, id: \.self) { milestone in
                let reached = progress >= milestone - 0.0001
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(reached ? AnyShapeStyle(palette.gradient) : AnyShapeStyle(Theme.surfaceSunken))
                            .frame(width: 30, height: 30)
                        Image(systemName: reached ? "checkmark" : "lock.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(reached ? Color.white : Theme.textTertiary)
                    }
                    Text("\(Int(milestone * 100))%")
                        .font(.captionSmall)
                        .foregroundStyle(reached ? Theme.textPrimary : Theme.textTertiary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .animation(.snappy(duration: 0.4), value: progress)
    }
}

#Preview {
    VStack(spacing: 20) {
        TransactionRow(transaction: SampleData.goals[0].sortedTransactions[0], currency: .ruble, palette: .ocean)
        MilestoneStrip(progress: 0.6, palette: .ocean)
    }
    .padding()
    .background(Theme.background)
}
