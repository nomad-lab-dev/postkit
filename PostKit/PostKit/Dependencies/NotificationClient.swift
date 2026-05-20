import ComposableArchitecture
import UserNotifications

@DependencyClient
struct NotificationClient: Sendable {
    var requestAuthorization: @Sendable () async throws -> Bool
    var scheduleWeekly: @Sendable (
        _ id: String,
        _ calendarWeekday: Int,
        _ hour: Int,
        _ minute: Int,
        _ title: String,
        _ body: String
    ) async throws -> Void
    var removePending: @Sendable (_ identifiers: [String]) async -> Void
}

extension NotificationClient: DependencyKey {
    static let liveValue = NotificationClient(
        requestAuthorization: {
            try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        },
        scheduleWeekly: { id, calendarWeekday, hour, minute, title, body in
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.weekday = calendarWeekday
            dateComponents.hour = hour
            dateComponents.minute = minute

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )
            let request = UNNotificationRequest(
                identifier: id,
                content: content,
                trigger: trigger
            )
            try await UNUserNotificationCenter.current().add(request)
        },
        removePending: { identifiers in
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    )

    static let previewValue = NotificationClient(
        requestAuthorization: { true },
        scheduleWeekly: { _, _, _, _, _, _ in },
        removePending: { _ in }
    )
}

extension DependencyValues {
    var notification: NotificationClient {
        get { self[NotificationClient.self] }
        set { self[NotificationClient.self] = newValue }
    }
}
