import UIKit

final class FeedCoordinator: FeedBaseCoordinator {
    weak var parentCoordinator: (any MainBaseCoordinator)?
   
    var rootViewController: UIViewController? = UIViewController()
    
    init() {}
    
    func start() -> UIViewController {
        showFeedScreen()
        return rootViewController ?? UIViewController()
    }
    
    func showFeedScreen() {
        let viewModel = FeedViewModel()
        let module = FeedViewController(feedViewModel: viewModel)
        module.showPost = { [weak self] in
            self?.showPost()
        }
        let navigationController = UINavigationController(rootViewController: module)
        rootViewController = navigationController
    }
    
    private func showPost() {
        guard rootViewController is UINavigationController else { return }
        let postViewController = PostViewController()
        postViewController.showInfo = { [weak self] in
            self?.showInfo()
        }
        postViewController.onBack = { [weak self] in
            self?.hide(style: .push)
        }
        show(viewController: postViewController, style: .push, animated: true)
    }
    
    private func showInfo() {
        let infoViewController = InfoViewController()
        infoViewController.modalTransitionStyle = .flipHorizontal
        infoViewController.modalPresentationStyle = .pageSheet
        show(viewController: infoViewController, style: .present, animated: true)
    }
}
