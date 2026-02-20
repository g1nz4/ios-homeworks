import UIKit

final class MainTabBarController: UITabBarController {
   
    private let user: User

    init(user: User) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
        setupTabItems()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupTabItems() {
        let feedViewController = FeedViewController()
        let feedViewNavigationController = UINavigationController(rootViewController: feedViewController)
        feedViewController.tabBarItem = UITabBarItem(
            title: "Лента",
            image: UIImage(systemName: "book"),
            tag: 0
        )
        
        let profileViewModel = ProfileViewModel(user: user)
        let profileViewController = ProfileViewController(viewModel: profileViewModel)
        let profileViewNavigationController = UINavigationController(rootViewController: profileViewController)
        profileViewController.tabBarItem = UITabBarItem(
            title: "Профиль",
            image: UIImage(systemName: "person.crop.circle"),
            tag: 1
        )
        viewControllers = [feedViewNavigationController, profileViewNavigationController]
        selectedIndex = 1
    }
}
