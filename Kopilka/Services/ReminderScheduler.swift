import Foundation
import UserNotifications

/// Еженедельное напоминание «пора отложить». Никакой аналитики и трекинга —
/// только локальные уведомления, поэтому приложение остаётся без сбора данных.
enum ReminderScheduler {
    static let identifier = "app.kopilka.weekly-reminder"

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func reschedule(settings: AppSettings) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard settings.reminderEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Время пополнить копилку"
        content.body = "Небольшая сумма сегодня — заметный результат через месяц."
        content.sound = .default

        var components = DateComponents()
        components.weekday = settings.reminderWeekday
        components.hour = settings.reminderHour
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    static let weekdayTitles: [Int: String] = [
        1: "Воскресенье",
        2: "Понедельник",
        3: "Вторник",
        4: "Среда",
        5: "Четверг",
        6: "Пятница",
        7: "Суббота"
    ]
}
