import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var loginCoordinator: LoginCoordinator?
    
    let notificationsService: LocalNotificationsServiceProtocol = LocalNotificationsService()
   
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let scene = (scene as? UIWindowScene) else { return }
           
        let window = UIWindow(windowScene: scene)
        
        let loginCoordinator = LoginCoordinator(notificationsService: notificationsService)
        self.loginCoordinator = loginCoordinator
        
        window.rootViewController = loginCoordinator.controller
        window.makeKeyAndVisible()
                
        self.window = window
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Ошибка:", error.localizedDescription)
        }
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        notificationsService.refreshAuthorizationStatus()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}

