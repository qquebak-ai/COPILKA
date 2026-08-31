import SwiftUI

/// Состояние ввода суммы. Отдельный тип, чтобы правила
/// (одна запятая, максимум две цифры после неё) жили в одном месте.
struct AmountInput: Equatable {
    private(set) var text: String = ""

    static let decimalSeparator = ","
    private static let maxIntegerDigits = 9

    var isEmpty: Bool { text.isEmpty }

    var value: Money {
        guard !text.isEmpty else { return .zero }
        let normalized = text.replacingOccurrences(of: Self.decimalSeparator, with: ".")
        return Money(string: normalized) ?? .zero
    }

    /// Что показываем на экране: разряды разделены пробелами, «хвост» сохраняется.
    var display: String {
        guard !text.isEmpty else { return "0" }
        let parts = text.split(separator: Character(Self.decimalSeparator), omittingEmptySubsequences: false)
        let integerPart = String(parts.first ?? "0")
        let grouped = Self.grouped(integerPart.isEmpty ? "0" : integerPart)
        if text.contains(Self.decimalSeparator) {
            let fraction = parts.count > 1 ? String(parts[1]) : ""
            return grouped + Self.decimalSeparator + fraction
        }
        return grouped
    }

    mutating func append(_ digit: String) {
        if digit == Self.decimalSeparator {
            guard !text.contains(Self.decimalSeparator) else { return }
            text = text.isEmpty ? "0" + Self.decimalSeparator : text + Self.decimalSeparator
            return
        }
        if let separatorIndex = text.firstIndex(of: Character(Self.decimalSeparator)) {
            let fractionLength = text.distance(from: text.index(after: separatorIndex), to: text.endIndex)
            guard fractionLength < 2 else { return }
        } else {
            guard text.count < Self.maxIntegerDigits else { return }
            if text == "0" { text = "" }
        }
        text += digit
    }

    mutating func deleteLast() {
        guard !text.isEmpty else { return }
        text.removeLast()
    }

    mutating func clear() {
        text = ""
    }

    mutating func set(_ amount: Money) {
        let rounded = amount.roundedToCents
        var string = "\(rounded)"
        string = string.replacingOccurrences(of: ".", with: Self.decimalSeparator)
        if string.hasSuffix(Self.decimalSeparator + "0") {
            string.removeLast(2)
        }
        text = string
    }

    private static func grouped(_ digits: String) -> String {
        var result = ""
        for (offset, character) in digits.reversed().enumerated() {
            if offset > 0 && offset % 3 == 0 { result.append(" ") }
            result.append(character)
        }
        return String(result.reversed())
    }
}

/// Клавиатура для сумм: крупные клавиши, тактильный отклик, без системного поля ввода.
struct NumberPadView: View {
    @Binding var input: AmountInput
    var hapticsEnabled: Bool = true

    private let rows: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [AmountInput.decimalSeparator, "0", "delete"]
    ]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { symbol in
                        keyButton(symbol)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func keyButton(_ value: String) -> some View {
        Button {
            HapticsService.shared.play(.light, enabled: hapticsEnabled)
            if value == "delete" {
                input.deleteLast()
            } else {
                input.append(value)
            }
        } label: {
            Group {
                if value == "delete" {
                    Image(systemName: "delete.left")
                        .font(.system(size: 21, weight: .medium))
                } else {
                    Text(value)
                        .font(.rounded(26, weight: .medium))
                }
            }
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                RoundedRectangle(cornerRadius: Metrics.smallRadius, style: .continuous)
                    .fill(Theme.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: Metrics.smallRadius, style: .continuous)
                            .strokeBorder(Theme.hairline, lineWidth: 1)
                    }
            }
            .contentShape(RoundedRectangle(cornerRadius: Metrics.smallRadius, style: .continuous))
        }
        .buttonStyle(PressableCardButtonStyle())
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45).onEnded { _ in
                guard value == "delete" else { return }
                HapticsService.shared.play(.warning, enabled: hapticsEnabled)
                input.clear()
            }
        )
        .accessibilityLabel(value == "delete" ? "Удалить" : value)
    }
}

private struct NumberPadPreview: View {
    @State private var input = AmountInput()

    var body: some View {
        VStack(spacing: 24) {
            Text(input.display).font(.displayLarge)
            NumberPadView(input: $input)
        }
        .padding()
        .background(Theme.background)
    }
}

#Preview {
    NumberPadPreview()
}
