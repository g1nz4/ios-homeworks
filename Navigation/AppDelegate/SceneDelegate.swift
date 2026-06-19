import UIKit

/// Точка входа для сцены. Отвечает за создание окна и стартового координатора.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var loginCoordinator: LoginCoordinator?
    
    let notificationsService = LocalNotificationsService()
   
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let scene = (scene as? UIWindowScene) else { return }
           
        let window = UIWindow(windowScene: scene)
        // Запрос разрешения на локальные уведомления
        self.notificationsService.registerForLatestUpdatesIfPossible()
       
        self.window = window
                
        Task { @MainActor in
            let factory = MyLoginFactory()
            // Корневой координатор авторизации
            let сoordinator = LoginCoordinator(factory: factory)
            сoordinator.setup()
            self.loginCoordinator = сoordinator
            
            window.rootViewController = сoordinator.controller
            window.makeKeyAndVisible()
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
       
    }
    
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

