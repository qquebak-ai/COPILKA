import SwiftUI

/// Экран ввода суммы: пополнение или снятие по конкретной цели.
struct AmountEntrySheet: View {
    @Environment(SavingsStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let goalID: Goal.ID
    var onFinish: (Bool, GoalPalette) -> Void

    @State private var kind: Transaction.Kind
    @State private var input = AmountInput()
    @State private var note = ""
    @FocusState private var isNoteFocused: Bool

    init(
        goalID: Goal.ID,
        kind: Transaction.Kind = .deposit,
        onFinish: @escaping (Bool, GoalPalette) -> Void = { _, _ in }
    ) {
        self.goalID = goalID
        self.onFinish = onFinish
        _kind = State(initialValue: kind)
    }

    private var goal: Goal? { store.goal(id: goalID) }
    private var palette: GoalPalette { goal?.palette ?? .gold }
    private var currency: CurrencyOption { store.currency }

    private var amount: Money { input.value }

    private var maxWithdrawal: Money { goal?.savedAmount ?? 0 }

    private var validationMessage: String? {
        guard kind == .withdrawal, amount > maxWithdrawal else { return nil }
        return "Больше, чем накоплено: \(maxWithdrawal.formatted(currency: currency))"
    }

    private var canSubmit: Bool {
        amount > 0 && validationMessage == nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground(palette: palette, intensity: 0.7)

                VStack(spacing: 18) {
                    kindPicker

                    amountDisplay

                    quickAmounts

                    noteField

                    if !isNoteFocused {
                        NumberPadView(input: $input, hapticsEnabled: store.settings.hapticsEnabled)
                            .transition(.opacity)
                    }

                    submitButton
                }
                .padding(.horizontal, Metrics.screenPadding)
                .padding(.bottom, 12)
            }
            .background(Theme.background)
            .navigationTitle(goal?.title ?? "Операция")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .animation(.snappy(duration: 0.25), value: isNoteFocused)
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - Части экрана

    private var kindPicker: some View {
        Picker("Тип операции", selection: $kind) {
            Text("Пополнить").tag(Transaction.Kind.deposit)
            Text("Снять").tag(Transaction.Kind.withdrawal)
        }
        .pickerStyle(.segmented)
        .padding(.top, 4)
    }

    private var amountDisplay: some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(kind == .deposit ? "+" : "−")
                Text(input.display)
                Text(currency.symbol)
                    .foregroundStyle(Theme.textSecondary)
            }
            .font(.rounded(46, weight: .bold))
            .foregroundStyle(input.isEmpty ? Theme.textTertiary : Theme.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .contentTransition(.numericText(value: amount.doubleValue))
            .animation(.snappy(duration: 0.25), value: input)

            if let validationMessage {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(Theme.negative)
            } else if let goal, kind == .deposit, goal.remainingAmount > 0 {
                Text("До цели осталось \(goal.remainingAmount.formatted(currency: currency))")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    private var quickAmounts: some View {
        HStack(spacing: 10) {
            ForEach(QuickAmounts.values(for: currency), id: \.self) { value in
                Button {
                    HapticsService.shared.play(.soft, enabled: store.settings.hapticsEnabled)
                    input.set(input.value + value)
                } label: {
                    Text("+\(value.formatted(currency: currency))")
                        .font(.caption)
                        .foregroundStyle(palette.accentColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background {
                            Capsule().fill(palette.tint)
                        }
                }
                .buttonStyle(PressableCardButtonStyle())
            }

            if kind == .deposit, let goal, goal.remainingAmount > 0 {
                Button {
                    HapticsService.shared.play(.soft, enabled: store.settings.hapticsEnabled)
                    input.set(goal.remainingAmount)
                } label: {
                    Text("До цели")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background { Capsule().fill(Theme.surfaceSunken) }
                }
                .buttonStyle(PressableCardButtonStyle())
            }
        }
    }

    private var noteField: some View {
        HStack(spacing: 10) {
            Image(systemName: "text.alignleft")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)

            TextField("Комментарий (необязательно)", text: $note)
                .font(.bodyRegular)
                .foregroundStyle(Theme.textPrimary)
                .focused($isNoteFocused)
                .submitLabel(.done)
                .onSubmit { isNoteFocused = false }

            if isNoteFocused {
                Button("Готово") { isNoteFocused = false }
                    .font(.caption)
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: Metrics.smallRadius, style: .continuous)
                .fill(Theme.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: Metrics.smallRadius, style: .continuous)
                        .strokeBorder(Theme.hairline, lineWidth: 1)
                }
        }
    }

    private var submitButton: some View {
        Button {
            submit()
        } label: {
            Text(kind == .deposit ? "Пополнить" : "Снять")
        }
        .buttonStyle(PrimaryButtonStyle(gradient: palette.gradient, isEnabled: canSubmit))
        .disabled(!canSubmit)
    }

    private func submit() {
        guard canSubmit else { return }
        let transaction = Transaction(
            amount: amount,
            kind: kind,
            date: .now,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        let justCompleted = store.addTransaction(transaction, to: goalID)
        let palette = self.palette
        dismiss()
        onFinish(justCompleted, palette)
    }
}

/// Быстрые суммы под клавиатурой — подстраиваются под порядок цифр валюты.
enum QuickAmounts {
    static func values(for currency: CurrencyOption) -> [Money] {
        switch currency.code {
        case "RUB": return [500, 1_000, 5_000]
        case "KZT": return [1_000, 5_000, 10_000]
        case "UAH", "TRY": return [100, 500, 1_000]
        case "AED": return [50, 100, 500]
        default: return [10, 50, 100]
        }
    }
}

#Preview {
    AmountEntrySheet(goalID: SampleData.goals[0].id)
        .environment(SampleData.store)
}
