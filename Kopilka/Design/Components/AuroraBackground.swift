import SwiftUI

/// Фон приложения: мягкие светящиеся пятна поверх базового цвета.
/// Двигаются медленно и почти незаметно — ощущение глубины без «дискотеки».
struct AuroraBackground: View {
    var palette: GoalPalette = .gold
    var intensity: Double = 1

    @State private var drift = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.background, Theme.backgroundDeep],
                startPoint: .top,
                endPoint: .bottom
            )

            blob(color: palette.highlightColor, size: 340)
                .offset(x: drift ? -110 : -80, y: drift ? -260 : -300)

            blob(color: palette.accentColor, size: 300)
                .offset(x: drift ? 140 : 110, y: drift ? -70 : -30)

            blob(color: Theme.accent, size: 380)
                .offset(x: drift ? -60 : -20, y: drift ? 320 : 360)
        }
        .ignoresSafeArea()
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 14).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }

    private func blob(color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .opacity(0.22 * intensity)
            .blur(radius: 90)
    }
}

#Preview {
    AuroraBackground(palette: .ocean)
}
