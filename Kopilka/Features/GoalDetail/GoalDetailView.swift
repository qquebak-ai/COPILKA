import SwiftUI

/// Экран цели: прогресс, темп, вехи и вся история операций.
struct GoalDetailView: View {
    @Environment(SavingsStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let goalID: Goal.ID

    @State private var entryKind: Transaction.Kind?
    @State private var isEditing = false
    @State private var isConfirmingDelete = false
    @State private var showsConfetti = false

    private var goal: Goal? { store.goal(id: goalID) }
    private var currency: CurrencyOption { store.currency }

    var body: some View {
        ZStack {
            if let goal {
                AuroraBackground(palette: goal.palette, intensity: 0.8)

                ScrollView {
                    VStack(spacing: Metrics.stackSpacing) {
                        hero(goal)
                        actions(goal)
                        facts(goal)
                        milestones(goal)
                        history(goal)
                    }
                    .padding(.horizontal, Metrics.screenPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
            } else {
                EmptyStateView(
                    symbolName: "questionmark.folder",
                    title: "Цель не найдена",
                    message: "Возможно, она была удалена."
                )
            }
        }
        .background(Theme.background)
        .navigationTitle(goal?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if goal != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            isEditing = true
                        } label: {
                            Label("Редактировать", systemImage: "pencil")
                        }

                        if let goal {
                            Button {
                                store.setArchived(!goal.isArchived, goalID: goal.id)
                            } label: {
                                Label(
                                    goal.isArchived ? "Вернуть из архива" : "В архив",
                                    systemImage: goal.isArchived ? "tray.and.arrow.up" : "archivebox"
                                )
                            }
                        }

                        Divider()

                        Button(role: .destructive) {
                            isConfirmingDelete = true
                        } label: {
                            Label("Удалить цель", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
            }
        }
        .sheet(item: $entryKind) { kind in
            AmountEntrySheet(goalID: goalID, kind: kind) { justCompleted, _ in
                if justCompleted { celebrate() }
            }
        }
        .sheet(isPresented: $isEditing) {
            if let goal {
                GoalEditorView(mode: .edit(goal))
            }
        }
        .confirmationDialog(
            "Удалить цель вместе с историей операций?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Удалить", role: .destructive) {
                store.delete(goalID: goalID)
                dismiss()
            }
            Button("Отмена", role: .cancel) {}
        }
        .overlay {
            if showsConfetti, let goal {
                ConfettiView(palette: goal.palette)
            }
        }
    }

    // MARK: - Секции

    private func hero(_ goal: Goal) -> some View {
        VStack(spacing: 18) {
            ZStack {
                ProgressRing(progress: goal.progress, palette: goal.palette, lineWidth: 16)
                    .frame(width: 208, height: 208)

                VStack(spacing: 6) {
                    IconBadge(symbolName: goal.symbolName, palette: goal.palette, size: 44)
                        .padding(.bottom, 2)

                    AnimatedMoneyText(
                        amount: goal.savedAmount,
                        currency: currency,
                        font: .rounded(28, weight: .bold)
                    )
                    .frame(maxWidth: 150)

                    Text("из \(goal.targetAmount.formatted(currency: currency))")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.top, 8)

            HStack(spacing: 8) {
                InfoChip(
                    text: goal.progressPercentString,
                    symbolName: "chart.pie.fill",
                    tint: goal.palette.accentColor
                )

                if goal.isCompleted {
                    InfoChip(text: "Цель достигнута", symbolName: "checkmark.seal.fill", tint: Theme.positive)
                } else if let description = goal.deadlineDescription {
                    InfoChip(
                        text: description,
                        symbolName: "calendar",
                        tint: goal.isOverdue ? Theme.negative : Theme.textSecondary
                    )
                }
            }

            if !goal.note.isEmpty {
                Text(goal.note)
                    .font(.bodyRegular)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .cardStyle(padding: 20)
    }

    private func actions(_ goal: Goal) -> some View {
        HStack(spacing: 12) {
            Button {
                entryKind = .deposit
            } label: {
                Label("Пополнить", systemImage: "plus")
            }
            .buttonStyle(PrimaryButtonStyle(gradient: goal.palette.gradient))

            Button {
                entryKind = .withdrawal
            } label: {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 16, weight: .bold))
            }
            .buttonStyle(SecondaryButtonStyle(tint: Theme.textSecondary))
            .frame(width: 64)
            .disabled(goal.savedAmount <= 0)
            .opacity(goal.savedAmount <= 0 ? 0.5 : 1)
            .accessibilityLabel("Снять деньги")
        }
    }

    private func facts(_ goal: Goal) -> some View {
        VStack(spacing: 0) {
            factRow(
                title: "Осталось накопить",
                value: goal.remainingAmount.formatted(currency: currency),
                symbolName: "flag.checkered"
            )

            if let weekly = goal.weeklyPace {
                divider
                factRow(
                    title: "Нужный темп",
                    value: "\(weekly.formatted(currency: currency)) в неделю",
                    symbolName: "bolt.fill"
                )
            }

            divider
            factRow(
                title: "Операций",
                value: "\(goal.transactions.count)",
                symbolName: "list.bullet"
            )

            divider
            factRow(
                title: "Создана",
                value: goal.createdAt.formatted(.dateTime.day().month(.abbreviated).year()),
                symbolName: "calendar.badge.plus"
            )
        }
        .cardStyle(padding: 6)
    }

    private var divider: some View {
        Divider()
            .overlay(Theme.hairline)
            .padding(.leading, 52)
    }

    private func factRow(title: String, value: String, symbolName: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbolName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Theme.surfaceSunken))

            Text(title)
                .font(.bodyRegular)
                .foregroundStyle(Theme.textSecondary)

            Spacer(minLength: 8)

            Text(value)
                .font(.bodyEmphasis)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }

    private func milestones(_ goal: Goal) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Вехи", subtitle: "Отмечаем каждый шаг")
            MilestoneStrip(progress: goal.progress, palette: goal.palette)
        }
        .cardStyle()
    }

    @ViewBuilder
    private func history(_ goal: Goal) -> some View {
        let transactions = goal.sortedTransactions
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: "История",
                subtitle: transactions.isEmpty
                    ? "Пока пусто"
                    : "\(transactions.count) \(Plural.operations(transactions.count))"
            )

            if transactions.isEmpty {
                Text("Первое пополнение появится здесь.")
                    .font(.bodyRegular)
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.vertical, 12)
            } else {
                ForEach(Array(transactions.enumerated()), id: \.element.id) { index, transaction in
                    TransactionRow(transaction: transaction, currency: currency, palette: goal.palette)
                        .contextMenu {
                            Button(role: .destructive) {
                                store.deleteTransaction(id: transaction.id, from: goal.id)
                            } label: {
                                Label("Удалить операцию", systemImage: "trash")
                            }
                        }

                    if index < transactions.count - 1 {
                        Divider().overlay(Theme.hairline)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func celebrate() {
        withAnimation(.easeOut(duration: 0.2)) { showsConfetti = true }
        Task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation(.easeOut(duration: 0.4)) { showsConfetti = false }
        }
    }
}

/// Позволяет открывать лист ввода через `.sheet(item:)`.
extension Transaction.Kind: Identifiable {
    var id: String { rawValue }
}

#Preview {
    NavigationStack {
        GoalDetailView(goalID: SampleData.goals[0].id)
    }
    .environment(SampleData.store)
}
