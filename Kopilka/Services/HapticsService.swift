import Foundation
import UIKit

/// Тактильный отклик. Вынесен в сервис, чтобы уважать переключатель в настройках
/// и не плодить генераторы по всему интерфейсу.
final class HapticsService {
    static let shared = HapticsService()

    enum Feedback {
        case light
        case medium
        case soft
        case selection
        case success
        case warning
    }

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()

    func prepare() {
        impactLight.prepare()
        impactSoft.prepare()
        selection.prepare()
    }

    func play(_ feedback: Feedback, enabled: Bool = true) {
        guard enabled else { return }
        DispatchQueue.main.async { [self] in
            switch feedback {
            case .light: impactLight.impactOccurred()
            case .medium: impactMedium.impactOccurred()
            case .soft: impactSoft.impactOccurred()
            case .selection: selection.selectionChanged()
            case .success: notification.notificationOccurred(.success)
            case .warning: notification.notificationOccurred(.warning)
            }
        }
    }
}
