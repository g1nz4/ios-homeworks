import UIKit
import StorageService

final class MainCoordinator: Coordinator {
   
    var controller: UIViewController
    var children: [Coordinator] = []

    private let feedCoordinator: FeedCoordinator
    private let profileCoordinator: ProfileCoordinator
    private let musicCoordinator: MusicCoordinator
    
    init(user: User) {
        feedCoordinator = FeedCoordinator()
        profileCoordinator = ProfileCoordinator(user: user)
        musicCoordinator = MusicCoordinator()
        
        let tabBar = UITabBarController()
        tabBar.viewControllers = [
            feedCoordinator.controller,
            musicCoordinator.controller,
            profileCoordinator.controller
        ]
        tabBar.selectedIndex = 1
        controller = tabBar
        children = [feedCoordinator, musicCoordinator, profileCoordinator]
    }

    func setup() { }
}
