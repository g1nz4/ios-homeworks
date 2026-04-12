import UIKit

final class FavoritesCoordinator: Coordinator {
    
    var controller: UIViewController
    var children: [Coordinator] = []
    
    init() {
        let favoritesVC = FavoritesTableViewController()
        let favoritesNC = UINavigationController(rootViewController: favoritesVC)
        favoritesVC.title = "Избранное"
        favoritesVC.tabBarItem = UITabBarItem(
            title: "Избранное",
            image: UIImage(systemName: "heart.fill"),
            selectedImage: UIImage(systemName: "heart.fill")
        )
        controller = favoritesNC
    }
    
    func setup() {}
}
