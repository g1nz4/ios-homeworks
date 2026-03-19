import UIKit
import StorageService

final class MainCoordinator: Coordinator {
   
    var controller: UIViewController
    var children: [Coordinator] = []

    private let infoCoordinator: InfoCoordinator
    private let profileCoordinator: ProfileCoordinator
    private let musicCoordinator: MusicCoordinator
    
    init(user: User) {
        infoCoordinator = InfoCoordinator()
        profileCoordinator = ProfileCoordinator(user: user)
        musicCoordinator = MusicCoordinator()
        
        let tabBar = UITabBarController()
        tabBar.viewControllers = [
            infoCoordinator.controller,
            musicCoordinator.controller,
            profileCoordinator.controller
        ]
        tabBar.selectedIndex = 0
        controller = tabBar
        children = [infoCoordinator, musicCoordinator, profileCoordinator]
    }

    func setup() { }
}
