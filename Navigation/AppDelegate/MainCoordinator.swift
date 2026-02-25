import UIKit
import StorageService

enum AppFlow {
    case feed
    case profile
}

final class MainCoordinator: MainBaseCoordinator {
    lazy var feedCoordinator: FeedBaseCoordinator = FeedCoordinator()
    lazy var profileCoordinator: ProfileBaseCoordinator = ProfileCoordinator()
    lazy var rootViewController: UIViewController = UITabBarController()
    
    private let user: User
    
    init(user: User) {
        self.user = user
    }
    
    func start() -> UIViewController {
        if let profileFlow = profileCoordinator as? ProfileCoordinator {
            profileFlow.user = user
        }
        
        let feedViewController = feedCoordinator.start()
        feedCoordinator.parentCoordinator = self
        feedViewController.tabBarItem = UITabBarItem(
            title: "Лента",
            image: UIImage(systemName: "book"),
            tag: 0
        )
        
        let profileViewController = profileCoordinator.start()
        profileCoordinator.parentCoordinator = self
        profileViewController.tabBarItem = UITabBarItem(
            title: "Профиль",
            image: UIImage(systemName: "person.crop.circle"),
            tag: 1
        )
    
        if let rootViewController = rootViewController as? UITabBarController {
            rootViewController.viewControllers = [feedViewController, profileViewController]
            rootViewController.selectedIndex = 1
        }
        return rootViewController
    }
    
    func moveTo(flow: AppFlow) {
        switch flow {
        case .feed:
            (rootViewController as? UITabBarController)?.selectedIndex = 0
        case .profile:
            (rootViewController as? UITabBarController)?.selectedIndex = 1
        }
    }

    func resetToRoot() -> Self {
        profileCoordinator.resetToRoot()
        moveTo(flow: .profile)
        return self
    }
}

