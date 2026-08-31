import SwiftUI

/// Конфетти при закрытии цели. Никаких сторонних библиотек:
/// набор фигур с заранее заданными траекториями, один прогон анимации.
struct ConfettiView: View {
    var palette: GoalPalette = .gold

    private struct Piece: Identifiable {
        let id = UUID()
        let x: Double
        let delay: Double
        let duration: Double
        let size: CGFloat
        let spin: Double
        let drift: Double
        let colorIndex: Int
        let isCircle: Bool
    }

    @State private var pieces: [Piece] = []
    @State private var launched = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var colors: [Color] {
        palette.colors + [Theme.accent, Color(hex: 0xFFFFFF), Color(hex: 0xF2C078)]
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                ForEach(pieces) { piece in
                    shape(for: piece)
                        .fill(colors[piece.colorIndex % colors.count])
                        .frame(width: piece.size, height: piece.size * (piece.isCircle ? 1 : 0.55))
                        .rotationEffect(.degrees(launched ? piece.spin : 0))
                        .offset(
                            x: proxy.size.width * piece.x + (launched ? piece.drift : 0),
                            y: launched ? proxy.size.height + 60 : -60
                        )
                        .opacity(launched ? 0 : 1)
                        .animation(
                            .easeIn(duration: piece.duration).delay(piece.delay),
                            value: launched
                        )
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            guard !reduceMotion else { return }
            pieces = Self.makePieces()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                launched = true
            }
        }
    }

    private func shape(for piece: Piece) -> AnyShape {
        piece.isCircle
            ? AnyShape(Circle())
            : AnyShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
    }

    private static func makePieces() -> [Piece] {
        (0..<64).map { index in
            Piece(
                x: Double.random(in: 0.02...0.96),
                delay: Double.random(in: 0...0.5),
                duration: Double.random(in: 1.5...2.6),
                size: CGFloat.random(in: 6...12),
                spin: Double.random(in: 220...900) * (index.isMultiple(of: 2) ? 1 : -1),
                drift: Double.random(in: -70...70),
                colorIndex: index,
                isCircle: index % 5 == 0
            )
        }
    }
}

#Preview {
    ZStack {
        Theme.background
        ConfettiView(palette: .sunset)
    }
    .ignoresSafeArea()
}
