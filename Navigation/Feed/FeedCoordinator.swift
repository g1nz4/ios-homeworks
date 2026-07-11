import UIKit

final class FeedCoordinator: Coordinator {
    
    var controller: UIViewController
    var children: [Coordinator]
    
//    let feedVC: FeedViewController
//    let feedNC: UINavigationController
//    
    enum Presentation {
        case post
        
    }
    
    init() {
        children = []
        
//        let viewModel = FeedViewModel()
//        feedVC = FeedViewController()
//        feedNC = UINavigationController(rootViewController: feedVC)
//        feedNC.tabBarItem = UITabBarItem(
//            title: "Лента",
//            image: UIImage(systemName: "text.bubble"),
//            selectedImage: UIImage(systemName: "text.bubble.fill")
//        )
  controller = UIViewController()
      //  setup()
    }
    
    func setup() {
       // feedVC.coordinator = self
    }
    
    func present(_ presentation: Presentation) {
//        switch presentation {
//        case .post:
//            let postVC = PostViewController()
//            postVC.coordinator = self
//            feedNC.pushViewController(postVC, animated: true)
//            
//            
//        }
        
        
    }
}
