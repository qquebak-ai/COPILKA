import SwiftUI

/// Создание и редактирование цели.
struct GoalEditorView: View {
    enum Mode {
        case create
        case edit(Goal)
    }

    @Environment(SavingsStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let mode: Mode

    @State private var title: String
    @State private var amountText: String
    @State private var symbolName: String
    @State private var palette: GoalPalette
    @State private var hasDeadline: Bool
    @State private var deadline: Date
    @State private var note: String
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case title
        case amount
        case note
    }

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .create:
            _title = State(initialValue: "")
            _amountText = State(initialValue: "")
            _symbolName = State(initialValue: GoalSymbol.defaultSymbol)
            _palette = State(initialValue: .gold)
            _hasDeadline = State(initialValue: false)
            _deadline = State(initialValue: Calendar.current.date(byAdding: .month, value: 6, to: .now) ?? .now)
            _note = State(initialValue: "")
        case let .edit(goal):
            _title = State(initialValue: goal.title)
            _amountText = State(initialValue: Self.editableAmount(goal.targetAmount))
            _symbolName = State(initialValue: goal.symbolName)
            _palette = State(initialValue: goal.palette)
            _hasDeadline = State(initialValue: goal.deadline != nil)
            _deadline = State(initialValue: goal.deadline ?? (Calendar.current.date(byAdding: .month, value: 6, to: .now) ?? .now))
            _note = State(initialValue: goal.note)
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var targetAmount: Money {
        Money(string: amountText.replacingOccurrences(of: ",", with: ".").filter { "0123456789.".contains($0) }) ?? 0
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && targetAmount > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground(palette: palette, intensity: 0.6)

                ScrollView {
                    VStack(spacing: Metrics.stackSpacing) {
                        previewCard
                        basicsCard
                        appearanceCard
                        deadlineCard
                        noteCard

                        if isEditing {
                            deleteButton
                        }
                    }
                    .padding(.horizontal, Metrics.screenPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .background(Theme.background)
            .navigationTitle(isEditing ? "Редактирование" : "Новая цель")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сохранить") { save() }
                        .font(.bodyEmphasis)
                        .foregroundStyle(canSave ? Theme.accent : Theme.textTertiary)
                        .disabled(!canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Готово") { focusedField = nil }
                }
            }
        }
    }

    // MARK: - Карточки

    private var previewCard: some View {
        HStack(spacing: 14) {
            IconBadge(symbolName: symbolName, palette: palette, size: 56)

            VStack(alignment: .leading, spacing: 6) {
                Text(title.isEmpty ? "Название цели" : title)
                    .font(.titleMedium)
                    .foregroundStyle(title.isEmpty ? Theme.textTertiary : Theme.textPrimary)
                    .lineLimit(1)

                Text(targetAmount > 0 ? targetAmount.formatted(currency: store.currency) : "Сумма не задана")
                    .font(.bodyRegular)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .cardStyle(padding: 16)
    }

    private var basicsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            fieldLabel("Название")
            TextField("Например, отпуск в Японии", text: $title)
                .font(.bodyEmphasis)
                .foregroundStyle(Theme.textPrimary)
                .focused($focusedField, equals: .title)
                .submitLabel(.next)
                .onSubmit { focusedField = .amount }
                .textFieldStyle(.plain)

            Divider().overlay(Theme.hairline)

            fieldLabel("Сумма цели")
            HStack(spacing: 8) {
                TextField("0", text: $amountText)
                    .font(.rounded(24, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .amount)

                Text(store.currency.symbol)
                    .font(.rounded(20, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            fieldLabel("Цвет")
            HStack(spacing: 10) {
                ForEach(GoalPalette.allCases) { option in
                    Button {
                        HapticsService.shared.play(.selection, enabled: store.settings.hapticsEnabled)
                        withAnimation(.snappy(duration: 0.3)) { palette = option }
                    } label: {
                        Circle()
                            .fill(option.gradient)
                            .frame(width: 34, height: 34)
                            .overlay {
                                Circle()
                                    .strokeBorder(Theme.textPrimary.opacity(palette == option ? 0.9 : 0), lineWidth: 2)
                                    .padding(-4)
                            }
                    }
                    .buttonStyle(PressableCardButtonStyle())
                    .accessibilityLabel(option.title)
                }
                Spacer(minLength: 0)
            }

            Divider().overlay(Theme.hairline)

            fieldLabel("Иконка")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                ForEach(GoalSymbol.all, id: \.self) { symbol in
                    Button {
                        HapticsService.shared.play(.selection, enabled: store.settings.hapticsEnabled)
                        withAnimation(.snappy(duration: 0.25)) { symbolName = symbol }
                    } label: {
                        Image(systemName: symbol)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(symbolName == symbol ? Color.white : Theme.textSecondary)
                            .frame(width: 42, height: 42)
                            .background {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(symbolName == symbol ? AnyShapeStyle(palette.gradient) : AnyShapeStyle(Theme.surfaceSunken))
                            }
                    }
                    .buttonStyle(PressableCardButtonStyle())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var deadlineCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: $hasDeadline.animation(.snappy(duration: 0.3))) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Срок")
                        .font(.bodyEmphasis)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Покажем, сколько нужно откладывать в неделю")
                        .font(.captionSmall)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .tint(palette.accentColor)

            if hasDeadline {
                DatePicker(
                    "Дата",
                    selection: $deadline,
                    in: Date.now...,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .font(.bodyRegular)
                .tint(palette.accentColor)
            }
        }
        .cardStyle()
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldLabel("Заметка")
            TextField("Зачем эта цель", text: $note, axis: .vertical)
                .font(.bodyRegular)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1...4)
                .focused($focusedField, equals: .note)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            if case let .edit(goal) = mode {
                store.delete(goalID: goal.id)
                dismiss()
            }
        } label: {
            Text("Удалить цель")
        }
        .buttonStyle(SecondaryButtonStyle(tint: Theme.negative))
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.captionSmall)
            .foregroundStyle(Theme.textTertiary)
            .kerning(0.6)
    }

    // MARK: - Сохранение

    private func save() {
        guard canSave else { return }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalDeadline = hasDeadline ? deadline : nil

        switch mode {
        case .create:
            let goal = Goal(
                title: trimmedTitle,
                targetAmount: targetAmount,
                symbolName: symbolName,
                palette: palette,
                deadline: finalDeadline,
                note: trimmedNote
            )
            store.add(goal)
        case let .edit(existing):
            var updated = existing
            updated.title = trimmedTitle
            updated.targetAmount = targetAmount.roundedToCents
            updated.symbolName = symbolName
            updated.palette = palette
            updated.deadline = finalDeadline
            updated.note = trimmedNote
            store.update(updated)
        }
        dismiss()
    }

    private static func editableAmount(_ amount: Money) -> String {
        var text = "\(amount.roundedToCents)"
        if text.hasSuffix(".0") { text.removeLast(2) }
        return text
    }
}

#Preview("Создание") {
    GoalEditorView(mode: .create)
        .environment(SampleData.store)
}

#Preview("Редактирование") {
    GoalEditorView(mode: .edit(SampleData.singleGoal))
        .environment(SampleData.store)
}
