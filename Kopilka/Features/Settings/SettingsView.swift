import SwiftUI

/// Настройки: оформление, валюта, напоминания, архив и данные.
struct SettingsView: View {
    @Environment(SavingsStore.self) private var store

    @State private var isConfirmingReset = false
    @State private var showsNotificationsDeniedAlert = false

    var body: some View {
        @Bindable var store = store

        return NavigationStack {
            ZStack {
                AuroraBackground(palette: .orchid, intensity: 0.5)

                ScrollView {
                    VStack(spacing: Metrics.stackSpacing) {
                        appearanceCard(store: store)
                        currencyCard(store: store)
                        remindersCard(store: store)
                        archiveCard
                        dataCard
                        aboutCard
                    }
                    .padding(.horizontal, Metrics.screenPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
                .scrollIndicators(.hidden)
            }
            .background(Theme.background)
            .navigationTitle("Настройки")
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .archive: ArchivedGoalsView()
                }
            }
            .confirmationDialog(
                "Удалить все цели и историю? Действие необратимо.",
                isPresented: $isConfirmingReset,
                titleVisibility: .visible
            ) {
                Button("Удалить всё", role: .destructive) { store.resetEverything() }
                Button("Отмена", role: .cancel) {}
            }
            .alert("Уведомления выключены", isPresented: $showsNotificationsDeniedAlert) {
                Button("Понятно", role: .cancel) {}
            } message: {
                Text("Разрешите уведомления в настройках системы, чтобы получать напоминания.")
            }
        }
    }

    // MARK: - Карточки

    private func appearanceCard(store: SavingsStore) -> some View {
        @Bindable var store = store

        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Оформление")

            HStack(spacing: 10) {
                ForEach(AppSettings.AppearanceOption.allCases) { option in
                    let isSelected = store.settings.appearance == option
                    Button {
                        HapticsService.shared.play(.selection, enabled: store.settings.hapticsEnabled)
                        withAnimation(.snappy(duration: 0.3)) {
                            store.settings.appearance = option
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: option.symbolName)
                                .font(.system(size: 17, weight: .semibold))
                            Text(option.title)
                                .font(.captionSmall)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .foregroundStyle(isSelected ? Theme.textOnAccent : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 70)
                        .background {
                            RoundedRectangle(cornerRadius: Metrics.smallRadius, style: .continuous)
                                .fill(isSelected ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Theme.surfaceSunken))
                        }
                    }
                    .buttonStyle(PressableCardButtonStyle())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func currencyCard(store: SavingsStore) -> some View {
        @Bindable var store = store

        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Валюта", subtitle: "Меняет только отображение сумм")

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                ForEach(CurrencyOption.all) { option in
                    let isSelected = store.settings.currencyCode == option.code
                    Button {
                        HapticsService.shared.play(.selection, enabled: store.settings.hapticsEnabled)
                        withAnimation(.snappy(duration: 0.25)) {
                            store.settings.currencyCode = option.code
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(option.symbol)
                                .font(.rounded(20, weight: .bold))
                            Text(option.code)
                                .font(.captionSmall)
                        }
                        .foregroundStyle(isSelected ? Theme.textOnAccent : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background {
                            RoundedRectangle(cornerRadius: Metrics.smallRadius, style: .continuous)
                                .fill(isSelected ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Theme.surfaceSunken))
                        }
                    }
                    .buttonStyle(PressableCardButtonStyle())
                    .accessibilityLabel(option.title)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func remindersCard(store: SavingsStore) -> some View {
        @Bindable var store = store

        return VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: $store.settings.hapticsEnabled) {
                settingLabel(title: "Тактильный отклик", subtitle: "Лёгкая вибрация при действиях", symbolName: "hand.tap.fill")
            }
            .tint(Theme.accent)

            Divider().overlay(Theme.hairline)

            Toggle(isOn: $store.settings.reminderEnabled) {
                settingLabel(title: "Напоминание", subtitle: "Раз в неделю подскажем отложить", symbolName: "bell.badge.fill")
            }
            .tint(Theme.accent)
            .onChange(of: store.settings.reminderEnabled) { _, isOn in
                Task { await handleReminderChange(isOn: isOn, store: store) }
            }

            if store.settings.reminderEnabled {
                VStack(spacing: 10) {
                    Picker("День", selection: $store.settings.reminderWeekday) {
                        ForEach(1...7, id: \.self) { day in
                            Text(ReminderScheduler.weekdayTitles[day] ?? "").tag(day)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.accent)

                    Picker("Время", selection: $store.settings.reminderHour) {
                        ForEach(6...23, id: \.self) { hour in
                            Text(String(format: "%02d:00", hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.accent)
                }
                .font(.bodyRegular)
                .foregroundStyle(Theme.textPrimary)
                .onChange(of: store.settings.reminderWeekday) { _, _ in
                    Task { await ReminderScheduler.reschedule(settings: store.settings) }
                }
                .onChange(of: store.settings.reminderHour) { _, _ in
                    Task { await ReminderScheduler.reschedule(settings: store.settings) }
                }
            }
        }
        .cardStyle()
    }

    private var archiveCard: some View {
        NavigationLink(value: SettingsRoute.archive) {
            HStack(spacing: 12) {
                settingLabel(
                    title: "Архив целей",
                    subtitle: store.archivedGoals.isEmpty ? "Пока пусто" : "\(store.archivedGoals.count) \(Plural.goals(store.archivedGoals.count))",
                    symbolName: "archivebox.fill"
                )
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .cardStyle()
        }
        .pressableCard()
    }

    private var dataCard: some View {
        VStack(spacing: 12) {
            Button {
                store.loadDemoData()
            } label: {
                Text("Загрузить демо-данные")
            }
            .buttonStyle(SecondaryButtonStyle(tint: Theme.textSecondary))

            Button {
                isConfirmingReset = true
            } label: {
                Text("Удалить все данные")
            }
            .buttonStyle(SecondaryButtonStyle(tint: Theme.negative))
        }
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "О приложении")

            Text("Копилка \(AppInfo.versionString)")
                .font(.bodyEmphasis)
                .foregroundStyle(Theme.textPrimary)

            Text("Все цели и операции хранятся только на вашем устройстве. Приложение не собирает аналитику и не требует регистрации.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func settingLabel(title: String, subtitle: String, symbolName: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbolName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Theme.accentSoft))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.bodyEmphasis)
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.captionSmall)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func handleReminderChange(isOn: Bool, store: SavingsStore) async {
        if isOn {
            let granted = await ReminderScheduler.requestAuthorization()
            if !granted {
                await MainActor.run {
                    store.settings.reminderEnabled = false
                    showsNotificationsDeniedAlert = true
                }
                return
            }
        }
        await ReminderScheduler.reschedule(settings: store.settings)
    }
}

enum SettingsRoute: Hashable {
    case archive
}

enum AppInfo {
    static var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    SettingsView()
        .environment(SampleData.store)
}
