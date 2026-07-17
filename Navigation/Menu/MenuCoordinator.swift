import UIKit

/// Делегат координатора меню.
/// Сообщает наружу, какой пункт меню был выбран.
protocol MenuCoordinatorDelegate: AnyObject {
    func menuCoordinatorDidRequestFriends(_ coordinator: MenuCoordinator, from host: UINavigationController)
    func menuCoordinatorDidRequestStoriesArchive(_ coordinator: MenuCoordinator, from host: UINavigationController)
    func menuCoordinatorDidRequestPhotos(_ coordinator: MenuCoordinator, from host: UINavigationController)
    func menuCoordinatorDidRequestMusic(_ coordinator: MenuCoordinator, from host: UINavigationController)
    func menuCoordinatorDidRequestFavorites(_ coordinator: MenuCoordinator, from host: UINavigationController)
    func menuCoordinatorDidRequestSettings(_ coordinator: MenuCoordinator, from host: UINavigationController)
    func menuCoordinatorDidRequestEditProfile(_ coordinator: MenuCoordinator, from host: UINavigationController)
    func menuCoordinatorDidRequestLogout(_ coordinator: MenuCoordinator)
}

/// Координатор экрана меню:
/// 1.  создаёт и показывает MenuCollectionViewController
/// 2.  реагирует на выбор пунктов меню и пробрасывает в делегата
final class MenuCoordinator: Coordinator {
    
    /// Варианты презентации внутри координатора
    enum Presentation {
        case main   // основное меню
        case info   // экран "О приложении"
    }

    weak var delegate: MenuCoordinatorDelegate?

    /// Корневой контроллер координатора
    var controller: UIViewController

    /// Дочерние координаторы
    var children: [Coordinator] = []

    /// Навигационный контроллер, которым управляет координатор
    var navigationController: UINavigationController { navController }

    private let navController: UINavigationController
    private let user: User


    init(
        user: User,
        navigationController: UINavigationController = UINavigationController()
    ) {
        self.user = user
        self.navController = navigationController
        self.controller = navigationController
        
        setup()
    }

    /// Первичная настройка координатора
    func setup() {
        present(.main)
    }

    /// Презентует нужный сценарий внутри координатора
    func present(_ presentation: Presentation) {
        switch presentation {

        case .main:
            let vm = MenuViewModel(user: user)
            let vc = MenuCollectionViewController(viewModel: vm)
            vc.coordinator = self
            
            // Обработка выбора пункта меню
            vc.onItemSelected = { [weak self] item in
                guard let self = self else { return }
                switch item {
                case .friends:
                    self.delegate?.menuCoordinatorDidRequestFriends(self, from: self.navController)
                case .storiesArchive:
                    self.delegate?.menuCoordinatorDidRequestStoriesArchive(self, from: self.navController)
                case .photos:
                    self.delegate?.menuCoordinatorDidRequestPhotos(self, from: self.navController)
                case .music:
                    self.delegate?.menuCoordinatorDidRequestMusic(self, from: self.navController)
                case .favorites:
                    self.delegate?.menuCoordinatorDidRequestFavorites(self, from: self.navController)
                case .settings:
                    self.delegate?.menuCoordinatorDidRequestSettings(self, from: self.navController)
                case .logout:
                    self.delegate?.menuCoordinatorDidRequestLogout(self)
                }
            }
            
            // Обработка нажатия "Редактировать профиль"
            vc.onEditProfileTap = { [weak self] in
                guard let self = self else { return }
                self.delegate?.menuCoordinatorDidRequestEditProfile(self, from: self.navController)
            }
            
            navController.setViewControllers([vc], animated: false)
            navController.setNavigationBarHidden(false, animated: false)
            
        case .info:
            // Экран "О приложении"
            let vm = AppInfoViewModel()
            let vc = AppInfoViewController(viewModel: vm)
            navController.present(vc, animated: false)
        }
    }

    /// Закрыть текущий VC через pop
    func closeVC() {
        navController.popViewController(animated: true)
    }

    /// Закрыть координатор модально
    func dismiss() {
        navController.dismiss(animated: true)
    }
}
