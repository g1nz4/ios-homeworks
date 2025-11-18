import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        
        guard let scene = (scene as? UIWindowScene) else { return }
           
        let window = UIWindow(windowScene: scene)
           
        let tabBarController =  UITabBarController()
        
        let feedViewController = FeedViewController()
        let profileViewController = ProfileViewController()
        let feedNavigationController = UINavigationController(rootViewController: feedViewController)
        let profileNavigationController = UINavigationController(rootViewController: profileViewController)
        
        feedNavigationController.tabBarItem = UITabBarItem(
            title: "Лента",
            image: UIImage(systemName: "book"),
            tag: 0
        )
        profileNavigationController.tabBarItem = UITabBarItem(
            title: "Профиль",
            image: UIImage(systemName: "person.crop.circle"),
            tag: 1
        )
        
        let controllers = [feedNavigationController, profileNavigationController]
        tabBarController.viewControllers = controllers
        tabBarController.selectedIndex = 0
                
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
                
        self.window = window
    }
}

