import SwiftUI

/// Столбчатый график пополнений по месяцам. Нарисован руками —
/// так проще держать фирменные градиенты и скругления.
struct MonthlyChartView: View {
    var buckets: [MonthlyBucket]
    var currency: CurrencyOption

    @State private var selectedID: Date?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var maxValue: Double {
        max(buckets.map { $0.deposits.doubleValue }.max() ?? 0, 1)
    }

    private var selected: MonthlyBucket? {
        buckets.first { $0.id == selectedID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(selected?.accessibleTitle ?? "Последние \(buckets.count) месяцев")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    Text((selected?.deposits ?? totalDeposits).formatted(currency: currency))
                        .font(.rounded(22, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                }
                Spacer(minLength: 8)
                if selected != nil {
                    Button("Сбросить") { withAnimation(.snappy) { selectedID = nil } }
                        .font(.caption)
                        .foregroundStyle(Theme.accent)
                }
            }

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(buckets) { bucket in
                    bar(for: bucket)
                }
            }
            .frame(height: 150)
        }
        .cardStyle(padding: 18)
    }

    private var totalDeposits: Money {
        buckets.reduce(Money.zero) { $0 + $1.deposits }
    }

    private func bar(for bucket: MonthlyBucket) -> some View {
        let value = bucket.deposits.doubleValue
        let ratio = value / maxValue
        let isSelected = selectedID == bucket.id
        let isDimmed = selectedID != nil && !isSelected

        return VStack(spacing: 8) {
            Text(value > 0 ? bucket.deposits.compactString : "")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .opacity(isSelected || selectedID == nil ? 1 : 0.3)

            GeometryReader { proxy in
                VStack {
                    Spacer(minLength: 0)
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Theme.brandGradient)
                        .frame(height: max(proxy.size.height * ratio, value > 0 ? 6 : 3))
                        .opacity(value > 0 ? (isDimmed ? 0.35 : 1) : 0.15)
                }
                .frame(maxWidth: .infinity)
            }

            Text(bucket.shortTitle)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textTertiary)
                .lineLimit(1)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.3)) {
                selectedID = isSelected ? nil : bucket.id
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(bucket.accessibleTitle)
        .accessibilityValue(bucket.deposits.formatted(currency: currency))
    }
}

#Preview {
    MonthlyChartView(buckets: SampleData.store.monthlyBuckets(), currency: .ruble)
        .padding()
        .background(Theme.background)
}
