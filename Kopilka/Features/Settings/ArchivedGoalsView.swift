import SwiftUI

/// Архив: цели, убранные с главной, но с сохранённой историей.
struct ArchivedGoalsView: View {
    @Environment(SavingsStore.self) private var store

    var body: some View {
        ZStack {
            AuroraBackground(palette: .graphite, intensity: 0.4)

            ScrollView {
                VStack(spacing: 12) {
                    if store.archivedGoals.isEmpty {
                        EmptyStateView(
                            symbolName: "archivebox",
                            title: "Архив пуст",
                            message: "Сюда попадают цели, которые вы убрали с главного экрана."
                        )
                        .cardStyle(padding: 20)
                        .padding(.top, 30)
                    } else {
                        ForEach(store.archivedGoals) { goal in
                            HStack(spacing: 14) {
                                IconBadge(symbolName: goal.symbolName, palette: goal.palette, size: 42, filled: false)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(goal.title)
                                        .font(.bodyEmphasis)
                                        .foregroundStyle(Theme.textPrimary)
                                        .lineLimit(1)
                                    Text("\(goal.savedAmount.formatted(currency: store.currency)) из \(goal.targetAmount.formatted(currency: store.currency))")
                                        .font(.captionSmall)
                                        .foregroundStyle(Theme.textSecondary)
                                }

                                Spacer(minLength: 8)

                                Button {
                                    store.setArchived(false, goalID: goal.id)
                                } label: {
                                    Image(systemName: "tray.and.arrow.up")
                                }
                                .buttonStyle(CircleIconButtonStyle(size: 36, tint: Theme.accent))
                                .accessibilityLabel("Вернуть из архива")
                            }
                            .cardStyle()
                            .contextMenu {
                                Button(role: .destructive) {
                                    store.delete(goalID: goal.id)
                                } label: {
                                    Label("Удалить навсегда", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Metrics.screenPadding)
                .padding(.vertical, 12)
            }
            .scrollIndicators(.hidden)
        }
        .background(Theme.background)
        .navigationTitle("Архив")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ArchivedGoalsView()
    }
    .environment(SampleData.store)
}
