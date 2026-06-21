import UIKit
import StorageService

protocol ProfileCoordinatorDelegate: AnyObject {
    func didLogout()
}

final class ProfileCoordinator: Coordinator {
    
    weak var delegate: ProfileCoordinatorDelegate?
    
    var controller: UIViewController
    var children: [Coordinator]

    let profileVC: ProfileViewController
    let profileNC: UINavigationController

    enum Presentation {
        case photos
    }

    private let user: User
    private let authService: SupabaseAuthService
    
    init(
        user: User,
        authService: SupabaseAuthService = SupabaseAuthService.shared
    ) {
        self.user = user
        self.authService = authService
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
    
    func didTapLogout() {
        Task {
            do {
                try await authService.logout()
            } catch {
                AppLogger.debug("Logout error: \(error)")
            }
            delegate?.didLogout()
        }
    }
}
