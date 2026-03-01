import UIKit
import StorageService

final class MainCoordinator: Coordinator {
   
    var controller: UIViewController
    var children: [Coordinator] = []

    private let feedCoordinator: FeedCoordinator
    private let profileCoordinator: ProfileCoordinator

    init(user: User) {
        feedCoordinator = FeedCoordinator()
        profileCoordinator = ProfileCoordinator(user: user)

        let tabBar = UITabBarController()
        tabBar.viewControllers = [
            feedCoordinator.controller,
            profileCoordinator.controller
        ]
        tabBar.selectedIndex = 1
        controller = tabBar
        children = [feedCoordinator, profileCoordinator]
    }

    func setup() { }
}
