import SwiftUI

/// Первый запуск: три экрана, выбор валюты и вход в приложение.
struct OnboardingView: View {
    @Environment(SavingsStore.self) private var store
    @State private var page = 0

    private let pages: [OnboardingPage] = OnboardingPage.all

    var body: some View {
        @Bindable var store = store

        return ZStack {
            AuroraBackground(palette: pages[min(page, pages.count - 1)].palette)

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                        VStack(spacing: 28) {
                            OnboardingArtwork(kind: item.artwork, palette: item.palette)
                                .frame(height: 260)

                            VStack(spacing: 12) {
                                Text(item.title)
                                    .font(.displayMedium)
                                    .foregroundStyle(Theme.textPrimary)
                                    .multilineTextAlignment(.center)

                                Text(item.subtitle)
                                    .font(.bodyRegular)
                                    .foregroundStyle(Theme.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 28)

                            if index == pages.count - 1 {
                                currencyChooser(store: store)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(.top, 40)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageIndicator

                VStack(spacing: 12) {
                    Button {
                        advance()
                    } label: {
                        Text(page == pages.count - 1 ? "Начать" : "Далее")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("Пропустить") {
                        finish()
                    }
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
                    .opacity(page == pages.count - 1 ? 0 : 1)
                }
                .padding(.horizontal, Metrics.screenPadding)
                .padding(.bottom, 20)
            }
        }
        .background(Theme.background)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule()
                    .fill(index == page ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Theme.hairline))
                    .frame(width: index == page ? 22 : 7, height: 7)
            }
        }
        .animation(.snappy(duration: 0.3), value: page)
        .padding(.bottom, 22)
    }

    private func currencyChooser(store: SavingsStore) -> some View {
        @Bindable var store = store

        return VStack(spacing: 10) {
            Text("Валюта")
                .font(.captionSmall)
                .foregroundStyle(Theme.textTertiary)

            HStack(spacing: 8) {
                ForEach(CurrencyOption.all.prefix(4)) { option in
                    let isSelected = store.settings.currencyCode == option.code
                    Button {
                        HapticsService.shared.play(.selection, enabled: store.settings.hapticsEnabled)
                        withAnimation(.snappy(duration: 0.25)) {
                            store.settings.currencyCode = option.code
                        }
                    } label: {
                        Text(option.symbol)
                            .font(.rounded(18, weight: .bold))
                            .foregroundStyle(isSelected ? Theme.textOnAccent : Theme.textSecondary)
                            .frame(width: 52, height: 44)
                            .background {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(isSelected ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Theme.surface))
                            }
                    }
                    .buttonStyle(PressableCardButtonStyle())
                    .accessibilityLabel(option.title)
                }
            }
        }
        .padding(.top, 4)
    }

    private func advance() {
        HapticsService.shared.play(.light, enabled: store.settings.hapticsEnabled)
        if page < pages.count - 1 {
            withAnimation(.snappy(duration: 0.35)) { page += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        store.settings.hasCompletedOnboarding = true
    }
}

struct OnboardingPage: Identifiable {
    enum Artwork {
        case ring
        case chart
        case shield
    }

    let id = UUID()
    let title: String
    let subtitle: String
    let palette: GoalPalette
    let artwork: Artwork

    static let all: [OnboardingPage] = [
        OnboardingPage(
            title: "Цель вместо\nпросто денег",
            subtitle: "Отпуск, техника, подушка безопасности. Каждая цель со своей суммой, сроком и цветом.",
            palette: .gold,
            artwork: .ring
        ),
        OnboardingPage(
            title: "Виден каждый\nшаг",
            subtitle: "Кольцо прогресса, темп на неделю и история пополнений — понятно, успеваете вы или нет.",
            palette: .ocean,
            artwork: .chart
        ),
        OnboardingPage(
            title: "Всё остаётся\nна устройстве",
            subtitle: "Без регистрации, рекламы и аналитики. Данные хранятся локально и никуда не отправляются.",
            palette: .forest,
            artwork: .shield
        )
    ]
}

/// Иллюстрации онбординга собраны из тех же элементов, что и интерфейс, —
/// поэтому первый экран не обманывает ожидания.
struct OnboardingArtwork: View {
    var kind: OnboardingPage.Artwork
    var palette: GoalPalette

    @State private var appeared = false

    var body: some View {
        ZStack {
            switch kind {
            case .ring:
                ZStack {
                    ProgressRing(progress: appeared ? 0.72 : 0.05, palette: palette, lineWidth: 20)
                        .frame(width: 190, height: 190)
                    VStack(spacing: 4) {
                        Text("72%")
                            .font(.rounded(34, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("до цели")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

            case .chart:
                HStack(alignment: .bottom, spacing: 14) {
                    ForEach(Array([0.35, 0.55, 0.42, 0.78, 0.92].enumerated()), id: \.offset) { index, value in
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(palette.gradient)
                            .frame(width: 30, height: appeared ? 190 * value : 10)
                            .animation(
                                .spring(response: 0.7, dampingFraction: 0.75).delay(Double(index) * 0.07),
                                value: appeared
                            )
                    }
                }
                .frame(height: 200, alignment: .bottom)

            case .shield:
                ZStack {
                    Circle()
                        .fill(palette.tint)
                        .frame(width: 190, height: 190)
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 92, weight: .semibold))
                        .foregroundStyle(palette.gradient)
                        .scaleEffect(appeared ? 1 : 0.85)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.8)) { appeared = true }
        }
    }
}

#Preview {
    OnboardingView()
        .environment(SampleData.store)
}
