import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var mainCoordinator: MainCoordinator?
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let scene = (scene as? UIWindowScene) else { return }
           
        let window = UIWindow(windowScene: scene)
        
        let logInViewController = LogInViewController()
        let loginFactory = MyLoginFactory()
        logInViewController.loginDelegate = loginFactory.makeLoginInspector()
        let loginNavigationController = UINavigationController(rootViewController: logInViewController)
        logInViewController.loginSuccess = { [weak self] user in
            guard let self = self else { return }
            
            let mainCoordinator = MainCoordinator(user: user)
            self.mainCoordinator = mainCoordinator
            
            let rootViewController = mainCoordinator.start()
            window.rootViewController = rootViewController
        }
   
        window.rootViewController = loginNavigationController
        window.makeKeyAndVisible()
                
        self.window = window
    }
}

