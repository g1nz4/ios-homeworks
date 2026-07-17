import UIKit


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
    
    private let onThemeChanged: (AppTheme) -> Void
    
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
    /// Локальный сервис ленты.
    private let feedService: LocalFeedServiceProtocol
    /// Локальный сервис историй (сторис).
    private let storyService: LocalStoryServiceProtocol
    /// Фабрика просмотрщика историй (story viewer).
    private let storyViewerFactory: StoryViewerFactory
    /// Хранилище пользовательских настроек (тема, свайп табов ...).
    private let settingsStorage: UserSettingsStorage
    /// Сервис локальных уведомлений.
    private let notificationsService: LocalNotificationsService
    /// Общий сервис плеера, шарится между модулями музыки и мини‑плеером.
    private let musicPlayer: MusicPlayerService
    /// Главная VM музыки (экран Music).
    private let musicViewModel: MusicViewModel
    /// VM мини‑плеера (панель внизу RootTabContainer).
    private let miniPlayerViewModel: MiniPlayerViewModel
    
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
        userService: SupabaseUserService,
        restClient: SupabaseRESTClient,
        settingsStorage: UserSettingsStorage,
        notificationsService: LocalNotificationsService,
        onThemeChanged: @escaping (AppTheme) -> Void
    ) {
        self.user = user
        self.authService = authService
        self.userService = userService
        self.settingsStorage = settingsStorage
        self.notificationsService = notificationsService
        self.onThemeChanged = onThemeChanged
        
        self.controller = UIViewController()
        
        // MARK: Сервисы уровня MainCoordinator
        self.albumCoversService = AlbumCoversService(userService: userService)
        self.photosRepository = SupabasePhotosRepository(userService: userService)
        self.postService = PostService(currentUser: user)
        self.feedService = LocalFeedService()
        self.storyService = LocalStoryService()
        
        // Хранилище историй (CoreData) + фабрика просмотрщика историй.
        let coreDataStoryStorage: CDStoryStorageProtocol = CDStoryStorage()
        let storyViewerFactory = DefaultStoryViewerFactory(
            coreDataStorage: coreDataStoryStorage,
            localStorage: self.storyService
        )
        self.storyViewerFactory = storyViewerFactory
        
        // MARK: Музыка — общий player и view model'и
        let player = LocalMusicService()
        self.musicPlayer = player
        // Главная VM музыки
        let musicVM = MusicViewModel(player: player)
        self.musicViewModel = musicVM
        // VM мини‑плеера, спрашивает у MusicViewModel о том, находится ли трек в "моих треках".
        let miniVM = MiniPlayerViewModel(
            player: player,
            isInMyTracksProvider: { [weak musicVM] id in
                musicVM?.isInMyTracks(id: id) ?? false
            }
        )
        self.miniPlayerViewModel = miniVM
        
        // MARK: Лента (Feed)
        let feedViewModel = MainFeedViewModel(
            currentUserId: user.id,
            storyService: storyService,
            feedService: feedService,
            postService: postService,
            photosRepository: photosRepository,
            currentUser: user
        )
        // Корневой VC ленты
        let feedVC = FeedCollectionViewController(viewModel: feedViewModel)
        // Координатор ленты
        let feedCoordinator = FeedCoordinator(
            rootViewController: feedVC,
            feedVM: feedViewModel,
            storyViewerFactory: storyViewerFactory
        )
        
        // MARK: Профиль
        // Координатор профиля и его стек навигации
        let profileCoordinator = ProfileCoordinator(
            user: user,
            authService: authService,
            userService: userService,
            albumCoversService: self.albumCoversService,
            photosRepository: self.photosRepository,
            postService: self.postService,
            storyViewerFactory: storyViewerFactory,
            settingsStorage: settingsStorage,
            notificationsService: notificationsService,
            musicViewModel: musicVM,
            onThemeChanged: onThemeChanged
        )
        
        // MARK: Меню
        // Отдельный навконтоллер для меню (кладётся в таббар)
        let menuNav = UINavigationController()
        // Координатор меню работает с этим навконтроллером
        let menuCoordinator = MenuCoordinator(
            user: user,
            navigationController: menuNav
        )
        
        // MARK: Музыка — отдельный навконтроллер
        let musicNav = UINavigationController()
        
        // MARK: RootTabContainerController
        let items = [
            TabItem(title: "", systemImageName: "house.fill"),
            TabItem(title: "", systemImageName: "music.note"),
            TabItem(title: "", systemImageName: "person.fill"),
            TabItem(title: "", systemImageName: "square.grid.2x2")
        ]
       
        // Контроллеры по индексам соответствуют табам
        let controllers: [UIViewController] = [
            feedCoordinator.controller,    // 0 — лента
            musicNav,                      // 1 — музыка (nav, наполняет MusicCoordinator)
            profileCoordinator.controller, // 2 — профиль
            menuCoordinator.controller     // 3 — меню
        ]
        
        // Корневой контейнер с табами + свайпом между табами
        let rootTabController = RootTabContainerController(
            controllers: controllers,
            items: items
        )
        // Включить/выключить свайп между табами в зависимости от настроек
        rootTabController.setTabsSwipeEnabled(settingsStorage.tabSwipeEnabled)
        
        // MARK: MusicCoordinator
        // Координатор музыки управляет своим UINavigationController, знает про RootTabContainer, чтобы разворачивать мини‑плеер.
        let musicCoordinator = MusicCoordinator(
            rootTabController: rootTabController,
            navigationController: musicNav,
            player: player,
            musicViewModel: musicVM,
            miniPlayerViewModel: miniVM
        )
        
        self.feedCoordinator = feedCoordinator
        self.profileCoordinator = profileCoordinator
        self.menuCoordinator = menuCoordinator
        self.rootTabController = rootTabController
        self.musicCoordinator = musicCoordinator
        
        // MARK: Callbacks / bindings
        // Из настроек профиля можно включать/выключать свайп табов.
        profileCoordinator.onTabSwipeChanged = { [weak rootTabController] isOn in
            rootTabController?.setTabsSwipeEnabled(isOn)
        }
        // Подписка на изменение состояния плеера — обновляем сразу две VM: экрана музыки и мини‑плеера.
        player.onStateChanged = { [weak self] state in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.musicViewModel.updateFromPlayer(state)
                self.miniPlayerViewModel.updateFromPlayer(state)
            }
        }
        
        // Инициализация VM начальными данными плеера
        let initialState = player.state
        musicVM.updateFromPlayer(initialState)
        miniVM.updateFromPlayer(initialState)
        
        // Привязка мини‑плеера к RootTabContainer
        bindMiniPlayer()
        
        // Корневой контроллер основного флоу — RootTabContainer
        self.controller = rootTabController
        
        // Иерархия дочерних координаторов
        self.children = [
            feedCoordinator,
            musicCoordinator,
            profileCoordinator,
            menuCoordinator
        ]
        
        // Делегатыдля событий таббара и меню
        rootTabController.delegate = self
        profileCoordinator.delegate = self
        menuCoordinator.delegate = self
    }
    
    func setup() {
        // Доп. настройка при старте (пока пусто)
    }
    
    func didLogout() {
        delegate?.mainCoordinatorDidRequestLogout(self)
    }
    
    // MARK: - MiniPlayer binding
    
    /// Конфигурация RootTabContainer так, чтобы он получал данные и обработчики событий мини‑плеера из MiniPlayerViewModel.
    private func bindMiniPlayer() {
        miniPlayerViewModel.onViewDataChanged = { [weak self] viewData in
            guard let self else { return }
            
            // Если данных нет — скрыть мини‑плеер
            guard let vd = viewData else {
                self.rootTabController.hideMiniPlayer()
                return
            }
            
            // конфиг для мини‑плеера из viewData
            let config = MiniPlayerConfig(
                fullTitle: vd.fullTitle,
                isPlaying: vd.isPlaying,
                isInMyTracks: vd.isInMyTracks,
                progress: vd.progress,
                repeatMode: vd.repeatMode
            )
            
            // Передача в RootTabContainer конфиг + набор замыканий‑экшенов
            self.rootTabController.updateMiniPlayer(
                config: config,
                onPlayPause: { [weak self] in
                    self?.miniPlayerViewModel.playPause()
                },
                onAddOrRemove: { [weak self] in
                    guard
                        let self,
                        let currentId = self.musicPlayer.state.currentTrack?.id
                    else { return }
                    self.musicViewModel.toggleMyTrack(id: currentId)
                },
                onClose: { [weak self] in
                    self?.miniPlayerViewModel.stop()
                },
                onPrev: { [weak self] in
                    self?.miniPlayerViewModel.prev()
                },
                onNext: { [weak self] in
                    self?.miniPlayerViewModel.next()
                },
                onSeek: { [weak self] value in
                    self?.miniPlayerViewModel.seek(to: value)
                },
                onToggleRepeat: { [weak self] in
                    self?.miniPlayerViewModel.toggleRepeat()
                }
            )
        }
    }
}


extension MainCoordinator: RootTabContainerControllerDelegate {
    /// Пользователь повторно нажал на активный таб.
    func tabWasReselected(index: Int) {
        if index == 2 { 
            profileCoordinator.popToRoot()
        }
    }
}

extension MainCoordinator: MenuCoordinatorDelegate {
    func menuCoordinatorDidRequestStoriesArchive(_ coordinator: MenuCoordinator, from host: UINavigationController) {
        // TODO: открыть архив сторис (скоро появится)
    }
    
    func menuCoordinatorDidRequestFriends(_ coordinator: MenuCoordinator, from host: UINavigationController) {
        profileCoordinator.present(.friends, in: host)
    }

    func menuCoordinatorDidRequestPhotos(_ coordinator: MenuCoordinator, from host: UINavigationController) {
        profileCoordinator.present(.photos, in: host)
    }

    func menuCoordinatorDidRequestMusic(_ coordinator: MenuCoordinator, from host: UINavigationController) {
        profileCoordinator.present(.music, in: host)
    }

    func menuCoordinatorDidRequestFavorites(_ coordinator: MenuCoordinator, from host: UINavigationController) {
        profileCoordinator.present(.favorites, in: host)
    }

    func menuCoordinatorDidRequestSettings(_ coordinator: MenuCoordinator, from host: UINavigationController) {
        profileCoordinator.present(.settings, in: host)
    }
    
    func menuCoordinatorDidRequestEditProfile(_ coordinator: MenuCoordinator, from host: UINavigationController) {
        profileCoordinator.present(.editProfile(user), in: host)
    }

    func menuCoordinatorDidRequestLogout(_ coordinator: MenuCoordinator) {
        didLogout()
    }
}
