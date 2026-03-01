import UIKit

final class FeedCoordinator: Coordinator {
    
    var controller: UIViewController
    var children: [Coordinator]
    
    let feedVC: FeedViewController
    let feedNC: UINavigationController
    
    enum Presentation {
        case post
        case info
    }
    
    init() {
        children = []

        let viewModel = FeedViewModel()
        feedVC = FeedViewController(feedViewModel: viewModel)
        feedNC = UINavigationController(rootViewController: feedVC)
        feedNC.tabBarItem = UITabBarItem(
            title: "Feed",
            image: UIImage(systemName: "text.bubble"),
            selectedImage: UIImage(systemName: "text.bubble.fill")
        )
        controller = feedNC
        setup()
    }

    func setup() {
        feedVC.coordinator = self
    }
    
    func present(_ presentation: Presentation) {
        switch presentation {
        case .post:
            let postVC = PostViewController()
            postVC.coordinator = self
            feedNC.pushViewController(postVC, animated: true)

        case .info:
            let infoVC = InfoViewController()
            feedNC.present(infoVC, animated: true, completion: nil)
        }
    }
    
    
}
