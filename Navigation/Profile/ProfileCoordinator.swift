import UIKit
import StorageService

final class ProfileCoordinator: Coordinator {
    
    var controller: UIViewController
    var children: [Coordinator]

    let profileVC: ProfileViewController
    let profileNC: UINavigationController

    enum Presentation {
        case photos
    }

    private let user: User
    
    init(user: User) {
        self.user = user
        children = []
        
        let viewModel = ProfileViewModel(user: user)
        profileVC = ProfileViewController(viewModel: viewModel)
        profileNC = UINavigationController(rootViewController: profileVC)
        profileNC.tabBarItem = UITabBarItem(
            title: "Профиль",
            image: UIImage(systemName: "person.crop.circle"),
            selectedImage: UIImage(systemName: "person.crop.circle.fill")
        )
        controller = profileNC
        setup()
    }

    func setup() {
        profileVC.coordinator = self
        profileVC.onShowPhotos = { [weak self] in
            self?.present(.photos)
        }
    }

    func present(_ presentation: Presentation) {
        switch presentation {
        case .photos:
            let photosVC = PhotosViewController()
            profileNC.pushViewController(photosVC, animated: true)
        }
    }
}
