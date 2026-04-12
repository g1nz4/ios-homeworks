import UIKit
import StorageService
import FirebaseAuth

final class MainCoordinator: Coordinator, ProfileCoordinatorDelegate {
   
    var controller: UIViewController
    var children: [Coordinator] = []

    private let feedCoordinator: FeedCoordinator
    private let musicCoordinator: MusicCoordinator
    private let profileCoordinator: ProfileCoordinator
    private let favoritesCoordinator: FavoritesCoordinator
    
    init(user: User) {
        feedCoordinator = FeedCoordinator()
        musicCoordinator = MusicCoordinator()
        profileCoordinator = ProfileCoordinator(user: user)
        favoritesCoordinator = FavoritesCoordinator()
        
        let tabBar = UITabBarController()
        tabBar.viewControllers = [
            feedCoordinator.controller,
            musicCoordinator.controller,
            profileCoordinator.controller,
            favoritesCoordinator.controller
        ]
        tabBar.selectedIndex = 3
        controller = tabBar
        children = [feedCoordinator, musicCoordinator, profileCoordinator, favoritesCoordinator]
        
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
