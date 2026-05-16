import Foundation
import UIKit
import UserNotifications

protocol LocalNotificationsServiceProtocol: AnyObject {
    func registerForLatestUpdatesIfPossible()
    func refreshAuthorizationStatus()
}

@MainActor
final class LocalNotificationsService: NSObject, LocalNotificationsServiceProtocol {
    
    private let center = UNUserNotificationCenter.current()
    
    enum AuthorizationStatus {
        case notDetermined, granted, denied
    }
    
    private(set) var authorizationStatus: AuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        center.delegate = self
    }
    
    func registerForLatestUpdatesIfPossible() {
        Task {
            registerUpdatesCategory()
            
            await updateAuthorizationStatus()
            
            if authorizationStatus == .notDetermined {
                let granted = await requestAuthorization()
                authorizationStatus = granted ? .granted : .denied
            }
            
            guard authorizationStatus == .granted else { return }
            
            await dailyUpdateNotification()
        }
    }
    
    func refreshAuthorizationStatus() {
        Task { [weak self] in
            await self?.updateAuthorizationStatus()
        }
    }
    
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
        print("Статус уведомлений: \(authorizationStatus)")
    }
    
    private func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.sound, .badge, .alert])
            return granted
        } catch {
            return false
        }
    }
    
    private func dailyUpdateNotification() async {
        center.removePendingNotificationRequests(
            withIdentifiers: ["latestUpdatesNotification"]
        )
        
        let content = UNMutableNotificationContent()
        content.title = "Обновления"
        content.body = "Посмотрите последние обновления"
        content.sound = .default
        content.badge = 1
        
        content.categoryIdentifier = "updates"
        
        var dateComponents = DateComponents()
        dateComponents.hour = 19
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "latestUpdatesNotification",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print("Не удалось запланировать уведомление: \(error)")
        }
    }
    
    private func registerUpdatesCategory() {
        let action = UNNotificationAction(
            identifier: "updatesAction",
            title: "Открыть обновления",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: "updates",
            actions: [action],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([category])
    }
}

extension LocalNotificationsService: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionID = response.actionIdentifier
        
        Task { @MainActor in
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        
        switch actionID {
        case "updatesAction":
            print("Пользователь нажал на 'Открыть обновления'")
            
        case UNNotificationDefaultActionIdentifier:
            print("Пользователь нажал на само уведомление")
            
        default:
            break
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}

