import SwiftUI

/// Кольцо прогресса с коническим градиентом и светящейся «головой» дуги.
struct ProgressRing: View {
    var progress: Double
    var palette: GoalPalette
    var lineWidth: CGFloat = 12
    var showsGlow: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.surfaceSunken, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            Circle()
                .trim(from: 0, to: max(clamped, 0.001))
                .stroke(palette.ringGradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(
                    color: showsGlow ? palette.accentColor.opacity(0.4) : .clear,
                    radius: 8
                )

            if clamped > 0.02 && clamped < 0.999 {
                GeometryReader { proxy in
                    let radius = min(proxy.size.width, proxy.size.height) / 2
                    Circle()
                        .fill(Color.white)
                        .frame(width: lineWidth * 0.42, height: lineWidth * 0.42)
                        .offset(y: -radius + lineWidth / 2)
                        .rotationEffect(.degrees(360 * clamped))
                        .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                        .opacity(0.9)
                }
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.8, dampingFraction: 0.85), value: clamped)
        .accessibilityElement()
        .accessibilityLabel("Прогресс")
        .accessibilityValue("\(Int(clamped * 100)) процентов")
    }
}

/// Горизонтальная полоса прогресса — для компактных карточек.
struct ProgressBarView: View {
    var progress: Double
    var palette: GoalPalette
    var height: CGFloat = 10

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Theme.surfaceSunken)

                Capsule(style: .continuous)
                    .fill(palette.gradient)
                    .frame(width: max(proxy.size.width * clamped, clamped > 0 ? height : 0))
                    .shadow(color: palette.accentColor.opacity(0.35), radius: 6, y: 2)
            }
        }
        .frame(height: height)
        .animation(reduceMotion ? nil : .spring(response: 0.7, dampingFraction: 0.85), value: clamped)
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 40) {
        ProgressRing(progress: 0.68, palette: .ocean, lineWidth: 16)
            .frame(width: 160, height: 160)
        ProgressBarView(progress: 0.42, palette: .sunset)
            .padding(.horizontal, 40)
    }
    .padding()
    .background(Theme.background)
}
