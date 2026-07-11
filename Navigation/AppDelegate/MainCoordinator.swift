import UIKit
import StorageService

/// Сообщает `AppCoordinator`, что пользователь вышел из аккаунта.
protocol MainCoordinatorDelegate: AnyObject {
    func mainCoordinatorDidRequestLogout(_ coordinator: MainCoordinator)
}

/// Главный координатор основного (залогиненного) флоу.
///
/// Отвечает за:
/// - настройку всех главных модулей (лента, музыка, профиль, меню)
/// - создание и конфигурацию `RootTabContainerController` с табами
/// - обработку событий профиля (logout / popToRoot и т.д.)
final class MainCoordinator: Coordinator, ProfileCoordinatorDelegate {
    
    /// Корневой контроллер этого координатора(`RootTabContainerController` с таббаром).
    var controller: UIViewController
    /// Дочерние координаторы (каждый управляет своим флоу).
    var children: [Coordinator] = []
    
    weak var delegate: MainCoordinatorDelegate?
    
    /// Текущий пользователь.
    private let user: User
    /// Сервис аутентификации (логин/логаут, хранение userID...)
    private let authService: SupabaseAuthService
    /// Сервис работы с профилями пользователей (загрузка/обновление и т.п.).
    private let userService: SupabaseUserService
    /// Сервис загрузки обложек альбомов(фото)..
    private let albumCoversService: AlbumCoversLoadingProtocol
    /// Хранилище / репозиторий фотографий пользователя (supabase).
    private let photosRepository: PhotosRepositoryProtocol
    /// Сервис работы с постами (лентой) текущего пользователя.
    private let postService: PostServiceProtocol
   
    /// Координатор главной ленты (feed).
    private let feedCoordinator: FeedCoordinator
    /// Координатор раздела музыка.
    private let musicCoordinator: MusicCoordinator
    /// Координатор профиля пользователя.
    private let profileCoordinator: ProfileCoordinator
    /// Координатор меню приложения.
    private let menuCoordinator: MenuCoordinator
    /// Корневой контроллер с таббаром и pageVC.
    private let rootTabController: RootTabContainerController
    
    init(
        user: User,
        authService: SupabaseAuthService,
        userService: SupabaseUserService
    ) {
        self.user = user
        self.authService = authService
        self.userService = userService
       
        self.controller = UIViewController()
        
        self.albumCoversService = AlbumCoversService(userService: userService)
        self.photosRepository = SupabasePhotosRepository(userService: userService)
        self.postService = PostService(currentUser: user)
        
        feedCoordinator = FeedCoordinator()
        musicCoordinator = MusicCoordinator()
        menuCoordinator = MenuCoordinator()
        profileCoordinator = ProfileCoordinator(
            user: user,
            authService: authService,
            userService: userService,
            albumCoversService: albumCoversService,
            photosRepository: photosRepository,
            postService: postService
        )
        
        let items = [
            TabItem(title: "", systemImageName: "house.fill"),
            TabItem(title: "", systemImageName: "music.note"),
            TabItem(title: "", systemImageName: "person.fill"),
            TabItem(title: "", systemImageName: "square.grid.2x2")
            
        ]
        
        
        rootTabController = RootTabContainerController(controllers: [
            feedCoordinator.controller,
            musicCoordinator.controller,
            profileCoordinator.controller,
            menuCoordinator.controller,
        ],
        items: items
        )
        // делегат для обработки событий таббара
        rootTabController.delegate = self
        controller = rootTabController
        children = [feedCoordinator, musicCoordinator, profileCoordinator, menuCoordinator]
        // Делегат профиля (для события logout) — MainCoordinator
        profileCoordinator.delegate = self
    }
    
    func setup() {
        
    }
    
    func didLogout() {
        delegate?.mainCoordinatorDidRequestLogout(self)
    }
}

extension MainCoordinator: RootTabContainerControllerDelegate {
    
    func tabWasReselected(index: Int) {
        if index == 2 { 
            profileCoordinator.popToRoot()
        }
    }
}
