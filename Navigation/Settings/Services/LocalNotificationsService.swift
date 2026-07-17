import Foundation
import UIKit
import UserNotifications

/// Сервис для работы с локальными уведомлениями приложения:
/// - запрашивает разрешения;
/// - планирует ежедневное уведомление с обновлениями;
/// - обрабатывает действия по уведомлениям.
@MainActor
final class LocalNotificationsService: NSObject {

    /// Статус авторизации для UI.
    enum AuthorizationStatus {
        case notDetermined
        case granted
        case denied
    }

    /// Центр уведомлений iOS.
    private let center = UNUserNotificationCenter.current()

    /// Текущий статус авторизации..
    private(set) var authorizationStatus: AuthorizationStatus = .notDetermined

    override init() {
        super.init()
        center.delegate = self
    }

 
    /// Зарегистрироваться на ежедневные уведомления об обновлениях, если это возможно.
    ///
    /// 1. Регистрирует категорию уведомлений.
    /// 2. Обновляет статус авторизации.
    /// 3. При необходимости запрашивает разрешение.
    /// 4. Если разрешение получено — планирует ежедневное уведомление.
    func registerForLatestUpdatesIfPossible() async {
        registerUpdatesCategory()

        await updateAuthorizationStatus()

        if authorizationStatus == .notDetermined {
            let granted = await requestAuthorizationInternal()
            authorizationStatus = granted ? .granted : .denied
        }

        guard authorizationStatus == .granted else { return }

        await scheduleDailyUpdateNotification()
    }

    /// Явно обновить сохранённый статус авторизации.
    func refreshAuthorizationStatus() async {
        await updateAuthorizationStatus()
    }

    /// Возвращает сырой системный статус авторизации (`UNAuthorizationStatus`).
    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    /// Запросить разрешение у пользователя и вернуть системный статус.
    func requestAuthorization() async -> UNAuthorizationStatus {
        let granted = await requestAuthorizationInternal()
        return granted ? .authorized : .denied
    }

    /// Включить ежедневное уведомление (если есть разрешение или его можно получить).
    func enableDailyUpdatesIfPossible() async {
        await registerForLatestUpdatesIfPossible()
    }

    /// Отключить ежедневное уведомление: удаляет запланированные и уже доставленные уведомления с этим идентификатором.
    func disableDailyUpdates() {
        center.removePendingNotificationRequests(
            withIdentifiers: [Constants.latestUpdatesNotificationID]
        )
        center.removeDeliveredNotifications(
            withIdentifiers: [Constants.latestUpdatesNotificationID]
        )
    }

    /// Обновляет `authorizationStatus` на основе системных настроек.
    private func updateAuthorizationStatus() async {
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            authorizationStatus = .notDetermined
        case .authorized, .provisional, .ephemeral:
            authorizationStatus = .granted
        case .denied:
            authorizationStatus = .denied
        @unknown default:
            authorizationStatus = .denied
        }

        AppLogger.debug("Статус уведомлений: \(authorizationStatus)")
    }

    /// Внутренний запрос авторизации. Возвращает `true`, если пользователь дал разрешение.
    private func requestAuthorizationInternal() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(
                options: [.sound, .badge, .alert]
            )
            return granted
        } catch {
            AppLogger.error("Ошибка при запросе разрешения на уведомления: \(error)")
            return false
        }
    }

    /// Планирует ежедневное уведомление с обновлениями на 19:00.
    private func scheduleDailyUpdateNotification() async {
        // Удалить предыдущий запрос с тем же идентификатором, чтобы не дублировать
        center.removePendingNotificationRequests(
            withIdentifiers: [Constants.latestUpdatesNotificationID]
        )

        let content = UNMutableNotificationContent()
        content.title = "Обновления"
        content.body = "Посмотрите последние обновления"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = Constants.updatesCategoryID

        var dateComponents = DateComponents()
        dateComponents.hour = 19
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: Constants.latestUpdatesNotificationID,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            AppLogger.error("Не удалось запланировать уведомление: \(error)")
        }
    }

    /// Регистрирует категорию уведомлений с action "Открыть обновления".
    private func registerUpdatesCategory() {
        let action = UNNotificationAction(
            identifier: Constants.updatesActionID,
            title: "Открыть обновления",
            options: [.foreground]
        )

        let category = UNNotificationCategory(
            identifier: Constants.updatesCategoryID,
            actions: [action],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([category])
    }
}

// MARK: - LocalNotificationsService.Constants

private extension LocalNotificationsService {
    enum Constants {
        static let latestUpdatesNotificationID = "latestUpdatesNotification"
        static let updatesCategoryID = "updates"
        static let updatesActionID = "updatesAction"
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension LocalNotificationsService: UNUserNotificationCenterDelegate {

    /// Обработка взаимодействий пользователя с уведомлением (тап по action или по самому уведомлению).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionID = response.actionIdentifier

        // Сбросить бейдж на иконке приложения
        Task { @MainActor in
            UIApplication.shared.applicationIconBadgeNumber = 0
        }

        switch actionID {
        case Constants.updatesActionID:
            AppLogger.debug("Пользователь нажал на 'Открыть обновления'")

        case UNNotificationDefaultActionIdentifier:
            AppLogger.debug("Пользователь нажал на само уведомление")

        default:
            break
        }

        completionHandler()
    }

    /// Отображение уведомления, когда приложение находится на переднем плане.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Показать баннер, звук и бейдж даже при открытом приложении
        completionHandler([.banner, .sound, .badge])
    }
}
