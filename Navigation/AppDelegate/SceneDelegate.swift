import UIKit

/// Точка входа для сцены. Отвечает за создание окна и стартового координатора.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    /// Главный координатор приложения, управляет выбором стартового флоу (логин / main).
    private var appCoordinator: AppCoordinator?
    
    private let notificationsService = LocalNotificationsService()
   
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let scene = (scene as? UIWindowScene) else { return }
           
        let window = UIWindow(windowScene: scene)
        
        let appCoordinator = AppCoordinator(window: window)
        self.appCoordinator = appCoordinator
        appCoordinator.setup()
        
        self.window = window
        window.rootViewController = appCoordinator.controller
        window.makeKeyAndVisible()
    }
    
    func sceneDidDisconnect(_ scene: UIScene) { }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        notificationsService.refreshAuthorizationStatus()
        if #available(iOS 17.0, *) {
           UNUserNotificationCenter.current()
               .setBadgeCount(0, withCompletionHandler: { _ in })
        } else {
           UIApplication.shared.applicationIconBadgeNumber = 0
        }

       // updateLastSeenIfNeeded()
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
      //  updateLastSeenIfNeeded()
    }
    
//    private func updateLastSeenIfNeeded() {
//        guard let userId = authService.userID else {
//            AppLogger.debug("updateLastSeenIfNeeded: userID == nil")
//            return
//        }
//
//        AppLogger.debug("updateLastSeenIfNeeded: userId = \(userId)")
//
//        Task {
//            do {
//                try await userService.updateLastSeen(userId: userId)
//                AppLogger.debug("updateLastSeen: OK")
//            } catch {
//                AppLogger.debug("updateLastSeen error: \(error)")
//            }
//        }
//    }
}

