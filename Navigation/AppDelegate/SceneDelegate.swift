import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var loginCoordinator: LoginCoordinator?
   
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let scene = (scene as? UIWindowScene) else { return }
           
        let window = UIWindow(windowScene: scene)
        
        let loginCoordinator = LoginCoordinator()
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
}

