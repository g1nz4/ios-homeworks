import UIKit

/// Делегат координатора профиля. Сейчас используется только для уведомления о logout (обратно в MainCoordinator).
protocol ProfileCoordinatorDelegate: AnyObject {
    /// Пользователь выполнил logout.
    func didLogout()
}

/// Координатор профиля: управляет стеком навигации вкладки `Профиль`.
final class ProfileCoordinator: Coordinator {
    
    weak var delegate: ProfileCoordinatorDelegate?
    /// Коллбэк изменения темы приложения, пробрасываемый из MainCoordinator.
    private let onThemeChanged: (AppTheme) -> Void
    
    /// Ссылка на текущий контроллер профиля.
    private weak var profileVC: ProfileViewController?
    /// ViewModel профиля, чтобы из координатора дергать обновления (reload и т.п.).
    private var profileViewModel: ProfileViewModel?
    
    var controller: UIViewController
    var children: [Coordinator]
    let navController: UINavigationController

    /// Коллбэк для переключения свайпа табов (пробрасывается в MainCoordinator).
    var onTabSwipeChanged: ((Bool) -> Void)?

    enum Presentation {
        case profile              // основной экран профиля
        case info                 // экран дополнительной информации
        case friends              // список друзей
        case publishPost          // создание нового поста
        case editPost(MyPost)     // редактирование существующего поста
        case photos               // экран фото
        case music                // экран музыка
        case favorites            // избранное
        case createStory          // создание истории
        case storyViewer          // просмотр историй
        case editProfile(User)    // редактирование профиля
        case settings             // экран настроек приложения
        
        case themeSelection(SettingsViewModel)       // экран выбора темы прриложения
        case languageSelection(SettingsViewModel)    // выбор языка приложения
    }

    private let user: User
    private let authService: SupabaseAuthService
    private let userService: SupabaseUserService
   
    private let albumCoversService: AlbumCoversLoadingProtocol
    private let photosRepository: PhotosRepositoryProtocol
    private let postService: PostServiceProtocol
    private let storyViewerFactory: StoryViewerFactory
    private let settingsStorage: UserSettingsStorage
    private let notificationsService: LocalNotificationsService
    private let musicViewModel: MusicViewModel
    
    init(
        user: User,
        authService: SupabaseAuthService,
        userService: SupabaseUserService,
        albumCoversService: AlbumCoversLoadingProtocol,
        photosRepository: PhotosRepositoryProtocol,
        postService: PostServiceProtocol,
        storyViewerFactory: StoryViewerFactory,
        settingsStorage: UserSettingsStorage,
        notificationsService: LocalNotificationsService,
        musicViewModel: MusicViewModel,
        onThemeChanged: @escaping (AppTheme) -> Void
    ) {
        self.user = user
        self.authService = authService
        self.userService = userService
        self.albumCoversService = albumCoversService
        self.photosRepository = photosRepository
        self.postService = postService
        self.storyViewerFactory = storyViewerFactory
        self.settingsStorage = settingsStorage
        self.notificationsService = notificationsService
        self.musicViewModel = musicViewModel
        self.onThemeChanged = onThemeChanged
        
        self.navController = UINavigationController()
        self.controller = navController
        children = []
        
        setup()
    }

    /// Точка входа координатора.
    func setup() {
        present(.profile)
    }
    /// Открыть сценарий в стандартном host (navController)
    func present(_ presentation: Presentation) {
        present(presentation, in: navController)
    }

    /// Открыть сценарий профиля в переданном UINavigationController.
    func present(_ presentation: Presentation, in host: UINavigationController) {
        switch presentation {
        case .profile:
            let storage = CDStoryStorage()
            let vm = ProfileViewModel(
                user: user,
                userService: userService,
                postService: postService,
                storyStorage: storage,
                albumCoversService: albumCoversService,
                photosRepository: photosRepository
            )
            let vc = ProfileViewController(viewModel: vm)
            vc.coordinator = self
            // Сохранить ссылки, чтобы потом иметь доступ к VM/VC из координатора
            self.profileViewModel = vm
            self.profileVC = vc
            
            host.setViewControllers([vc], animated: false)
            host.setNavigationBarHidden(false, animated: false)
            
        case .friends:
            let vm = FriendsViewModel(userService: userService, currentUser: user)
            let vc = FriendsCollectionViewController(viewModel: vm)
            vc.coordinator = self
            host.pushViewController(vc, animated: true)
            
        case .photos:
            let vm = PhotosViewModel(
                user: user,
                photosRepository: photosRepository,
                albumCoversService: albumCoversService,
                mode: .main
            )
            // Обновить профиль при изменении фотографии
            vm.onAvatarChanged = { [weak self] in
                Task { [weak self] in
                    await self?.profileViewModel?.headerVM.reloadProfile()
                }
            }
            // Обновить профиль при изменении обложки
            vm.onCoverChanged = { [weak self] in
                Task { [weak self] in
                    await self?.profileViewModel?.headerVM.reloadProfile()
                }
            }
            
            let vc = PhotosViewController(viewModel: vm)
            vc.coordinator = self
            vc.delegate = self // чтобы при изменениях в фото обновлять профиль
            host.pushViewController(vc, animated: true)
            
        case .music:
            let vc = MusicCollectionViewController(
                viewModel: musicViewModel,
                presentationStyle: .pushed
            )
            host.pushViewController(vc, animated: true)
            
        case .publishPost:
            let vm = PublishPostViewModel(postService: postService as! PostService, user: user)
            let vc = PublishPostViewController(viewModel: vm)
            vc.delegate = profileVC
            vc.coordinator = self
            
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            host.present(nav, animated: true)
            
        case .editPost(let post):
            let vm = PublishPostViewModel(postService: postService as! PostService, user: user, editingPost: post)
            let vc = PublishPostViewController(viewModel: vm)
            vc.delegate = profileVC
            vc.coordinator = self
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            host.present(nav, animated: true)
            
        case .info:
            let currentUser = profileViewModel?.currentUser ?? profileViewModel?.headerUser ?? user
            let vm = ProfileInfoViewModel(user: currentUser)
            let vc = ProfileInfoViewController(viewModel: vm)
            host.present(vc, animated: false)
            
        case .favorites:
            let vm = FavoritesViewModel(postService: postService)
            let vc = FavoritesCollectionViewController(
                user: user,
                viewModel: vm
            )
            vc.coordinator = self
            host.setNavigationBarHidden(false, animated: false)
            host.pushViewController(vc, animated: true)
            
        case .createStory:
            let storage = CDStoryStorage()
            let timer = StoryTimer()
            let vm = StoryCreationViewModel(
                timer: timer,
                storage: storage,
                userId: user.id
            )
            let vc = StoryViewController(creationViewModel: vm)
            vc.delegate = self
            vc.modalPresentationStyle = .fullScreen
            host.present(vc, animated: true)
            
        case .storyViewer:
            let currentUser = profileViewModel?.currentUser ?? profileViewModel?.headerUser ?? user
            let vc = storyViewerFactory.makeViewerForProfile(user: currentUser)
            vc.modalPresentationStyle = .fullScreen
            host.present(vc, animated: true)
            
        case .editProfile(let user):
            let vm = ProfileEditViewModel(user: user, userService: userService)
            let vc = ProfileEditViewController(viewModel: vm)
            // При успешном сохранении профиля:
            vm.onSaved = { [weak self] updated in
                guard let self else { return }
                
                Task { [weak self] in
                    guard let self else { return }
                    // Обновить имя автора во всех локальных постах
                    await self.postService.syncCurrentUserNameInPosts()
                    // Перечитать посты профиля
                    await self.profileViewModel?.postsVM.loadPosts(for: .posts)
                    // Обновить данные пользователя
                    await self.profileViewModel?.applyUpdatedUserAndReload(updated)
                }
                
                // Закрыть экран редактирования
                host.popViewController(animated: true)
            }
            // Пользователь ничего не изменил и нажал "Сохранить"
            vm.onNoChanges = { [weak self] in
                self?.closeVC()
            }
            host.pushViewController(vc, animated: true)
            
        case .settings:
            let vm = SettingsViewModel(
                settingsStorage: settingsStorage,
                notificationsService: notificationsService,
                permissionService: PermissionService.shared
            )
            
            // 1. Пробос изменений темы наружу (в MainCoordinator через onThemeChanged)
            vm.outputs.onThemeChanged = { [weak self] theme in
                self?.onThemeChanged(theme)
            }
            
            // 2. Открытие ThemeSelection host, что и настройки
            vm.outputs.onOpenThemeSelection = { [weak self, weak host] in
                guard let self, let host else { return }
                self.present(.themeSelection(vm), in: host)
            }
            
            vm.outputs.onOpenLanguageSelection = { [weak self, weak host] in
                guard let self, let host else { return }
                self.present(.languageSelection(vm), in: host)
            }
            
            vm.outputs.onTabSwipeChanged = { [weak self] isOn in
                self?.onTabSwipeChanged?(isOn)
            }
            
            let vc = SettingsTableViewController(viewModel: vm)
            host.pushViewController(vc, animated: true)
            
            
        case .themeSelection(let settingsVM):
            let vm = ThemeSelectionViewModel(currentTheme: settingsVM.currentTheme)
            
            vm.onThemeSelected = { [weak settingsVM, weak host] theme in
                settingsVM?.didSelectTheme(theme)
                host?.popViewController(animated: true)
            }
            
            let vc = ThemeSelectionViewController(viewModel: vm)
            host.pushViewController(vc, animated: true)
            
        case .languageSelection(let settingsVM):
            let vm = LanguageSelectionViewModel(currentLanguage: settingsVM.currentLanguage)

            vm.onLanguageSelected = { [weak settingsVM, weak host] language in
                settingsVM?.didSelectLanguage(language)   // сохранить + обновить таблицу
                host?.popViewController(animated: true)   // закрыть экран выбора языка
            }

            let vc = LanguageSelectionViewController(viewModel: vm)
            host.pushViewController(vc, animated: true)
        }
    }
    
    /// Вернуться на корневой экран стека (профиль).
    func popToRoot() {
        navController.popToRootViewController(animated: true)
    }
    
    /// Закрыть текущий VC (pop).
    func closeVC() {
        navController.popViewController(animated: true)
    }
    
    /// Закрыть модально представленный контроллер (dismiss).
    func dismiss() {
        navController.dismiss(animated: true)
    }
    
    /// Обработчик выхода из профиля.
    @objc func didTapLogout() {
        Task {
            do {
                try await authService.logout()
            } catch {
                AppLogger.debug("Logout error: \(error)")
            }
            // Уведомить AppCoordinator - перейти на логин
            delegate?.didLogout()
        }
    }
}

// MARK: - StoryViewControllerDelegate

extension ProfileCoordinator: StoryViewControllerDelegate {
    /// История успешно опубликована.
    func storyCreationDidPublish(
        _ controller: StoryViewController,
        items: [UIImage]
    ) {
        // Обновить флаг наличия истории в профиле
        if let profileVC = profileVC {
            profileVC.setHasStory(true)
        }
        dismiss()
    }
    
    /// Создание истории отменено.
    func storyCreationDidCancel(_ controller: StoryViewController) {
       dismiss()
    }
}

// MARK: - Дополнительные переходы ProfileCoordinator

extension ProfileCoordinator {
    /// Открыть экран фотографий конкретного альбома: `album`- альбом, содержимое которого нужно показать, `delegate`- тот, кого уведомлять об изменениях.
    func showAlbumPhotos(
        album: PhotoAlbum,
        delegate: PhotosViewControllerDelegate?
    ) {
        let vm = PhotosViewModel(
            user: user,
            photosRepository: photosRepository,
            albumCoversService: albumCoversService,
            mode: .album(album)
        )
        // Аватар/обложка могут поменяться через действия
        vm.onAvatarChanged = { [weak self] in
            Task { [weak self] in
                await self?.profileViewModel?.headerVM.reloadProfile()
            }
        }

        vm.onCoverChanged = { [weak self] in
            Task { [weak self] in
                await self?.profileViewModel?.headerVM.reloadProfile()
            }
        }
        
        let vc = PhotosViewController(viewModel: vm)
        vc.coordinator = self
        vc.delegate = delegate // проброс изменений наверх
        navController.pushViewController(vc, animated: true)
    }
    
    /// Открыть просмотрщик фото из ProfileViewController (координатор сам выступает делегатом PhotoViewerViewController).
    func showPhotoViewer(photos: [Photo], startIndex: Int) {
        let vc = PhotosViewerViewController(photos: photos, startIndex: startIndex)
        vc.delegate = self
        navController.pushViewController(vc, animated: true)
    }

    /// Открыть просмотр фото с явным делегатом: `photos`- массив фото, между которыми можно листать; `startIndex`- индекс стартового фото, `delegate`- объект, который будет получать события (set avatar / cover / delete / saved);  `showAddToSaved` - нужно ли показывать пункт `Добавить в сохранённые` в меню.
    func showPhotoViewer(
        photos: [Photo],
        startIndex: Int,
        delegate: PhotoViewerViewControllerDelegate,
        showAddToSaved: Bool = true,
        viewInPost: Bool = false
    ) {
        let vc = PhotosViewerViewController(
            photos: photos,
            startIndex: startIndex,
            showAddToSaved: showAddToSaved,
            viewInPost: viewInPost
        )
        vc.delegate = delegate
        navController.pushViewController(vc, animated: true)
    }
}

// MARK: - PhotoViewerViewControllerDelegate (реализация в координаторе)

extension ProfileCoordinator: PhotoViewerViewControllerDelegate {
    /// Пользователь выбрал `Сделать фото аватаром` в меню полноэкранного просмотра фото.
    func photoViewer(
        _ vc: PhotosViewerViewController,
        didChooseAvatarFrom photo: Photo
    ) {
        Task { [weak self] in
            await self?.profileViewModel?.setAvatar(from: photo)
        }
    }
    
    /// Пользователь выбрал `Сделать обложкой профиля` в меню полноэкранного просмотра фото.
    func photoViewer(
        _ vc: PhotosViewerViewController,
        didChooseCoverFrom photo: Photo
    ) {
        Task { [weak self] in
            await self?.profileViewModel?.setCover(from: photo)
        }
    }
    
    /// Пользователь добавил фото в `Сохранённые`.
    func photoViewer(
        _ vc: PhotosViewerViewController,
        didAddToSaved photo: Photo
    ) {
        Task { [weak self] in
            await self?.profileViewModel?.addToSaved(photo: photo)
        }
    }
    
    /// Пользователь удалил фото.
    func photoViewer(
        _ vc: PhotosViewerViewController,
        didDelete photo: Photo
    ) {
        Task { [weak self] in
            await self?.profileViewModel?.delete(photo: photo)
        }
        closeVC()
    }
}

// MARK: - PhotosViewControllerDelegate (координатор как делегат экранов Фото)

extension ProfileCoordinator: PhotosViewControllerDelegate {
    /// Вызывается из PhotosViewController при изменении фото/альбомов.
    func photosDidChange() {
        Task { [weak self] in
            await self?.profileViewModel?.reloadPhotos(force: true)
        }
    }
}
