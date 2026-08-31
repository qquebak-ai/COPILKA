import SwiftUI

/// Развилка запуска: онбординг для нового пользователя, вкладки — для всех остальных.
struct RootView: View {
    @Environment(SavingsStore.self) private var store

    var body: some View {
        ZStack {
            if store.settings.hasCompletedOnboarding {
                MainTabView()
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.45), value: store.settings.hasCompletedOnboarding)
    }
}

struct MainTabView: View {
    @Environment(SavingsStore.self) private var store
    @State private var selection: Tab = .goals

    enum Tab: Hashable {
        case goals
        case stats
        case settings
    }

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tag(Tab.goals)
                .tabItem {
                    Label("Цели", systemImage: "target")
                }

            StatsView()
                .tag(Tab.stats)
                .tabItem {
                    Label("Статистика", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tag(Tab.settings)
                .tabItem {
                    Label("Настройки", systemImage: "gearshape.fill")
                }
        }
        .onChange(of: selection) { _, _ in
            HapticsService.shared.play(.selection, enabled: store.settings.hapticsEnabled)
        }
    }
}

#Preview {
    RootView()
        .environment(SampleData.store)
}
