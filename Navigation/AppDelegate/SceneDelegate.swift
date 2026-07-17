import UIKit

/// Точка входа для сцены. Отвечает за создание окна и стартового координатора.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    /// Главный координатор приложения, управляет выбором стартового флоу (логин / main).
    private var appCoordinator: AppCoordinator?
    
    private let settingsStorage = UserSettingsStorage()
    private let notificationsService = LocalNotificationsService()
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let scene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: scene)
        
        LocalizationManager.configure(storage: settingsStorage)
        
        let appCoordinator = AppCoordinator(window: window, settingsStorage: settingsStorage)
        self.appCoordinator = appCoordinator
        appCoordinator.setup()
        
        self.window = window
        window.rootViewController = appCoordinator.controller
        window.makeKeyAndVisible()
    }
    
    func sceneDidDisconnect(_ scene: UIScene) { }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        Task { @MainActor in
            await notificationsService.refreshAuthorizationStatus()
        }
        if #available(iOS 17.0, *) {
            UNUserNotificationCenter.current()
                .setBadgeCount(0, withCompletionHandler: { _ in })
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        guard let root = window?.rootViewController else { return }
        
        // Поиск верхнего видимого контроллера
        _ = SceneDelegate.topViewController(from: root)
        
    }
    
    static func topViewController(from root: UIViewController?) -> UIViewController? {
        guard let root = root else { return nil }
        
        // presented
        if let presented = root.presentedViewController {
            return topViewController(from: presented)
        }
        
        // navigation
        if let nav = root as? UINavigationController {
            return topViewController(from: nav.visibleViewController)
        }
    
        // Кастомный контейнер табов
        if let rootTabs = root as? RootTabContainerController {
            return topViewController(from: rootTabs.currentChild)
        }
        
        // Прочие контейнеры
        for child in root.children {
            if let top = topViewController(from: child) {
                return top
            }
        }
        
        // Ничего не найдено – верхний root 
        return root
    }
}


