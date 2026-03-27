import UIKit
import StorageService
import FirebaseAuth

final class MainCoordinator: Coordinator, ProfileCoordinatorDelegate {
   
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
        tabBar.selectedIndex = 2
        controller = tabBar
        children = [feedCoordinator, musicCoordinator, profileCoordinator]
        
        profileCoordinator.delegate = self
    }

    func setup() {}
    
    func didLogout() {
        showLogin()
    }
    
    private func showLogin() {
        let loginCoordinator = LoginCoordinator()
        children = [loginCoordinator]
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController = loginCoordinator.controller
            window.makeKeyAndVisible()
        }
    }
}
