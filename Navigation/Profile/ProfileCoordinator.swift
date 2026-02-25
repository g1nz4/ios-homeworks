import UIKit
import StorageService

final class ProfileCoordinator: ProfileBaseCoordinator {
    weak var parentCoordinator: MainBaseCoordinator?
    var rootViewController: UIViewController? = UIViewController()
    var user: User!
    
    init() {}
    
    func start() -> UIViewController {
        showProfileScreen()
        return rootViewController ?? UIViewController()
    }
    
    func showProfileScreen() {
        let viewModel = ProfileViewModel(user: user)
        let module = ProfileViewController(viewModel: viewModel)
        viewModel.showPhotos = {[weak self] in
            self?.showPhotos()
        }
        let navigationController = UINavigationController(rootViewController: module)
        rootViewController = navigationController
    }
    
    private func showPhotos() {
        guard rootViewController is UINavigationController else { return }
        let photosViewController = PhotosViewController()
        show(viewController: photosViewController, style: .push, animated: true)
    }
}
