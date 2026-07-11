import UIKit
import StorageService

protocol ProfileCoordinatorDelegate: AnyObject {
    /// Пользователь выполнил logout.
    func didLogout()
}

/// Координатор профиля: управляет стеком навигации вкладки `Профиль`.
final class ProfileCoordinator: Coordinator {
    
    weak var delegate: ProfileCoordinatorDelegate?
  
    /// Ссылка на текущий контроллер профиля.
    private weak var profileVC: ProfileViewController?
    /// ViewModel профиля, чтобы из координатора дергать обновления (reload и т.п.).
    private var profileViewModel: ProfileViewModel?
    
    var controller: UIViewController
    var children: [Coordinator]

    let navController: UINavigationController

    enum Presentation {
        case profile              // основной экран профиля
        case info                 // экран дополнительной информации
        case friends              // список друзей
        case publishPost          // создание нового поста
        case editPost(MyPost)     // редактирование существующего поста
        case photos               // экран фото
        case favorites            // избранное
        case createStory          // создание истории
        case storyViewer          // просмотр историй
        case editProfile(User)    // редактирование профиля
        case settings             // экран настроек приложения
    }

    private let user: User
    private let authService: SupabaseAuthService
    private let userService: SupabaseUserService
    
    private let albumCoversService: AlbumCoversLoadingProtocol
    private let photosRepository: PhotosRepositoryProtocol
    private let postService: PostServiceProtocol
    
    init(
        user: User,
        authService: SupabaseAuthService,
        userService: SupabaseUserService,
        albumCoversService: AlbumCoversLoadingProtocol,
        photosRepository: PhotosRepositoryProtocol,
        postService: PostServiceProtocol,
    ) {
        self.user = user
        self.authService = authService
        self.userService = userService
        self.albumCoversService = albumCoversService
        self.photosRepository = photosRepository
        self.postService = postService
        
        self.navController = UINavigationController()
        self.controller = navController
        children = []
        
        setup()
    }

    /// Точка входа координатора.
    func setup() {
        present(.profile)
    }

    func present(_ presentation: Presentation) {
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
            
            navController.setViewControllers([vc], animated: false)
            navController.setNavigationBarHidden(false, animated: false)
            
        case .friends:
            let vc = FriendsViewController()
            vc.coordinator = self
            navController.pushViewController(vc, animated: true)
            
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
            navController.pushViewController(vc, animated: true)
            
        case .publishPost:
            let vm = PublishPostViewModel()
            let vc = PublishPostViewController(user: user, viewModel: vm)
            vc.delegate = profileVC
            vc.coordinator = self
            
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            navController.present(nav, animated: true)
            
        case .editPost(let post):
            let vm = PublishPostViewModel()
            let vc = PublishPostViewController(user: user, viewModel: vm, editingPost: post)
            vc.delegate = profileVC
            vc.coordinator = self
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            navController.present(nav, animated: true)
            
        case .info:
            let currentUser = profileViewModel?.currentUser ?? profileViewModel?.headerUser ?? user
            let vm = ProfileInfoViewModel(user: currentUser)
            let vc = ProfileInfoViewController(viewModel: vm)
            navController.present(vc, animated: false)
            
        case .favorites:
            let vm = FavoritesViewModel(postService: postService)
            let vc = FavoritesCollectionViewController(
                user: user,
                viewModel: vm
            )
            vc.coordinator = self
            vc.favoritesDelegate = profileVC
            navController.setNavigationBarHidden(false, animated: false)
            navController.pushViewController(vc, animated: true)
            
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
            navController.present(vc, animated: true)
            
        case .storyViewer:
            let storage = CDStoryStorage()
            let timer = StoryTimer()
            let vm = StoryPlayerViewModel(
                timer: timer,
                storage: storage,
                userId: user.id
            )
            let currentUser = profileViewModel?.currentUser ?? profileViewModel?.headerUser ?? user
            let name = currentUser.name.displayName
            let avatarURLString = currentUser.avatarURL?.absoluteString
            
            let vc = StoryViewController(
                playerViewModel: vm,
                mode: .viewOnly,
                userName: name,
                avatarURLString: avatarURLString
            )
            vc.modalPresentationStyle = .fullScreen
            navController.present(vc, animated: true)
            
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
                    await self.profileViewModel?.postsVM.loadPosts()
                    // Обновить данные пользователя
                    await self.profileViewModel?.applyUpdatedUserAndReload(updated)
                }
              
                // Закрыть экран редактирования
                self.closeVC()
            }
            // Пользователь ничего не изменил и нажал "Сохранить"
            vm.onNoChanges = { [weak self] in
                self?.closeVC()
            }
            navController.pushViewController(vc, animated: true)
            
        case .settings:
            let vm = SettingsViewModel()
            let vc = SettingsTableViewController(viewModel: vm)
            navController.pushViewController(vc, animated: true)
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
        showAddToSaved: Bool = true
    ) {
        let vc = PhotosViewerViewController(
            photos: photos,
            startIndex: startIndex,
            showAddToSaved: showAddToSaved
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
            await self?.profileViewModel?.reloadPhotos()
        }
    }
}
