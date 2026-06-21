import UIKit

/// Точка входа для сцены. Отвечает за создание окна и стартового координатора.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    /// Главный координатор приложения, управляет выбором стартового флоу (логин / main).
    private var appCoordinator: AppCoordinator?
    
    let notificationsService = LocalNotificationsService()
   
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let scene = (scene as? UIWindowScene) else { return }
           
        let window = UIWindow(windowScene: scene)
        
        let appCoordinator = AppCoordinator()
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
    }
}

