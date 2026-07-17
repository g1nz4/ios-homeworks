import Foundation

/// Типы ячеек, которые отображатются в коллекции профиля.
enum ProfileCellType {
    case friends          // капсула "Друзья"
    case publish          // капсула "Опубликовать пост"
    case tabs             // ячейка с табами (main / posts / photos / music)
    case photoAlbums      // горизонтальный список альбомов
    case photoItem        // одно фото в гриде
    case posts            // посты пользователя
    case emptyMessage     // универсальная заглушка (нет постов/фото/музыки)
    case none             // ничего (ячейка не используется)
}

/// Вкладки профиля.
enum ProfileTab {
    case main       // главная лента (посты добавленные из ленты новостей + посты пользователя)
    case posts      // посты только текущего пользователя
    case photos     // альбомы + фотографии
    case music      // пока заглушка
}

/// ViewModel экрана профиля.
/// Собирает в себе: 1) headerVM (аватар, имя,  инфо, сторис), 2) postsVM (посты и избранное), 3) photosVM (альбомы и фото),  и предоставляет API для контроллера/handler’а.
@MainActor
final class ProfileViewModel {

    let headerVM: ProfileHeaderViewModel
    let postsVM: ProfilePostsViewModel
    let photosVM: PhotosViewModel
    // let musicVM: MusicViewModel //  позже

    private let userService: SupabaseUserService

    /// Чтобы не грузить фото на каждый заход во вкладку photos повторно, отмечаем, что начальная загрузка уже была.
    private var didInitialPhotosLoad = false

    /// Текущий пользователь (данные для header’а и т.п.).
    private(set) var user: User

    /// Текущий выбранный таб.
    private(set) var selectedTab: ProfileTab = .main

    // Состояние по друзьям
    private(set) var friendsCount: Int = 0
    private(set) var friendAvatarURLs: [URL] = []

    var hasStory: Bool { headerVM.hasStory }
    var headerUser: User? { user }
    var currentUser: User { headerVM.user }
    var currentTab: ProfileTab { selectedTab }


    /// Старт/стоп pull‑to‑refresh.
    var onRefreshingChanged: ((Bool) -> Void)?
    /// Обновление header’а (шапки профиля).
    var updateHeader: ((User) -> Void)?
    /// Смена таба (нужно перелэйаутить коллекцию и т.п.).
    var onTabChanged: (() -> Void)?
    /// Ошибка.
    var onError: ((AppError) -> Void)?
    /// Изменение флага наличия сторис.
    var onStoryFlagChanged: ((Bool) -> Void)?
    /// Список избранных постов поменялся.
    var onFavoritesChanged: (() -> Void)?
    /// Фото/альбомы были обновлены.
    var onPhotosChanged: (() -> Void)?

    var onFriendsChanged: (() -> Void)?

    init(
        user: User,
        userService: SupabaseUserService,
        postService: PostServiceProtocol,
        storyStorage: CDStoryStorageProtocol,
        albumCoversService: AlbumCoversLoadingProtocol,
        photosRepository: PhotosRepositoryProtocol
    ) {
        self.user = user
        self.userService = userService
        
        self.headerVM = ProfileHeaderViewModel(
            user: user,
            userService: userService,
            storyStorage: storyStorage
        )

        self.postsVM = ProfilePostsViewModel(postService: postService)

        self.photosVM = PhotosViewModel(
            user: user,
            photosRepository: photosRepository,
            albumCoversService: albumCoversService,
            mode: .main
        )

        bindSubViewModels()
        observeSavedPhotosChanges()
    }

    /// Подписки на события дочерних вьюмоделей (header/posts/photos).
    private func bindSubViewModels() {
        // Обновление пользователя из headerVM
        headerVM.onUserChanged = { [weak self] user in
            guard let self else { return }
            self.user = user
            self.updateHeader?(user)
            
            NotificationCenter.default.post(
                name: .currentUserDidUpdate,
                object: nil,
                userInfo: [CurrentUserUpdateKey.user: user]
            )
        }

        // Ошибка headerVM
        headerVM.onError = { [weak self] error in
            self?.onError?(error)
        }

        // Флаг наличия сторис
        headerVM.onStoryFlagChanged = { [weak self] hasStory in
            self?.onStoryFlagChanged?(hasStory)
        }

        // Изменение избранного в постах
        postsVM.onFavoritesChanged = { [weak self] in
            self?.onFavoritesChanged?()
        }

        // Любое изменение фото/альбомов
        photosVM.onChanged = { [weak self] in
            self?.onPhotosChanged?()
        }

        // Аватар был изменён из photos‑раздела — перезагрузить header
        photosVM.onAvatarChanged = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.headerVM.reloadProfile()
            }
        }

        // Обложка была изменена — обновить header
        photosVM.onCoverChanged = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.headerVM.reloadProfile()
            }
        }
    }
    
    private func observeSavedPhotosChanges() {
        NotificationCenter.default.addObserver(
            forName: .savedPhotosDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { [weak self] in
                await self?.reloadPhotos(force: true)
            }
        }
    }
    
    private func loadFriends() async {
        defer { onFriendsChanged?() }
        
        do {
            let users = try await userService.fetchFriends(for: user.id)
        
            friendsCount = user.friendsCount ?? users.count
            friendAvatarURLs = users
                .compactMap { $0.avatarURL }
                .prefix(3)
                .map { $0 }
            
        } catch {
            AppLogger.error("loadFriends error: \(error)")
            friendsCount = 0
            friendAvatarURLs = []
        }
    }
    
    
    
    // Данные для капсулы друзья, вызывается из хендлера
    func friendsSummary() -> (count: Int, avatars: [URL]) {
        (friendsCount, friendAvatarURLs)
    }


    /// Полная перезагрузка профиля.
    /// header и посты грузятся параллельно, фото — только на вкладке .photos.
    func reloadProfile(isPullToRefresh: Bool = false) async {
        if isPullToRefresh {
            onRefreshingChanged?(true)
        }

        defer {
            if isPullToRefresh {
                onRefreshingChanged?(false)
            }
        }

        async let headerTask: Void = headerVM.reloadProfile()
        async let postsTask: Void  = postsVM.loadPosts(for: selectedTab)
        async let friendsTask: Void = loadFriends()

        if selectedTab == .photos {
            async let photosTask: Void = photosVM.load(force: isPullToRefresh)
            _ = await (headerTask, postsTask, friendsTask, photosTask)
        } else {
            _ = await (headerTask, postsTask, friendsTask)
        }

        onStoryFlagChanged?(headerVM.hasStory)
    }

    /// Фасад для координатора: взять обновлённые пользовательские данные и перезагрузить профиль.
    func applyUpdatedUserAndReload(_ updatedUser: User, isPullToRefresh: Bool = false) async {
        await applyUpdatedUser(updatedUser)
        await reloadProfile(isPullToRefresh: isPullToRefresh)
    }

    /// Обновляет локального `user` и headerVM без перезагрузки всего профиля.
    func applyUpdatedUser(_ user: User) async {
        self.user = user
        headerVM.update(with: user)
    }

    /// Принудительно перезагружает только фото/альбомы.
    func reloadPhotos(force: Bool = false) async {
        await photosVM.load(force: force)
    }

    /// Переключение вкладки (main/posts/photos/music).
    func selectTab(_ tab: ProfileTab) async {
        guard tab != selectedTab else { return }

        selectedTab = tab

        if tab == .photos {
            if !didInitialPhotosLoad {
                didInitialPhotosLoad = true
            }
            onTabChanged?()
            await photosVM.load()
        } else {
            if tab == .main || tab == .posts {
                await postsVM.loadPosts(for: tab)
            }
            onTabChanged?()
        }
    }

    /// Количество секций в коллекции.
    func numberOfSections() -> Int {
        switch selectedTab {
        case .photos:
            // 0: профиль, 1: табы+посты/заглушка, 2: альбомы, 3: фото
            return 4
        default:
            // 0: профиль, 1: табы+посты/заглушка
            return 2
        }
    }

    /// Количество строк (item’ов) в секции.
    func numberOfRows(in section: Int) -> Int {
        switch section {
        case 0:
            // 0 секция: friends + publish
            return 2

        case 1:
            switch selectedTab {
            case .main, .posts:
                let postsCount = postsVM.count
                // tabs + (посты или одна заглушка)
                return 1 + max(postsCount, 1)

            case .music:
                // tabs + заглушка
                return 2

            case .photos:
                let hasAnyPhotos = !photosVM.albums.isEmpty || !photosVM.photos.isEmpty
                // tabs + (если пусто – заглушка, если нет – ничего)
                return 1 + (hasAnyPhotos ? 0 : 1)
            }

        case 2:
            // Альбомы (только во вкладке .photos и если есть хоть какие-то данные)
            guard selectedTab == .photos else { return 0 }
            guard !photosVM.albums.isEmpty || !photosVM.photos.isEmpty else { return 0 }
            return photosVM.albums.count

        case 3:
            // Фотографии (только во вкладке .photos)
            guard selectedTab == .photos else { return 0 }
            guard !photosVM.albums.isEmpty || !photosVM.photos.isEmpty else { return 0 }
            return photosVM.photos.count

        default:
            return 0
        }
    }

    /// Тип ячейки для конкретной позиции.
    func cellType(for section: Int, item: Int) -> ProfileCellType {
        switch section {

        case 0:
            // 0: friends, 1: publish
            return item == 0 ? .friends : .publish

        case 1:
            if item == 0 {
                return .tabs
            } else {
                switch selectedTab {
                case .main, .posts:
                    // если постов нет — заглушка
                    return postsVM.count == 0 ? .emptyMessage : .posts

                case .music:
                    // пока всегда заглушка после tabs
                    return .emptyMessage

                case .photos:
                    // если нет ни альбомов, ни фото — заглушка
                    let hasAnyPhotos = !photosVM.albums.isEmpty || !photosVM.photos.isEmpty
                    return hasAnyPhotos ? .none : .emptyMessage
                }
            }

        case 2:
            return selectedTab == .photos ? .photoAlbums : .none

        case 3:
            return selectedTab == .photos ? .photoItem : .none

        default:
            return .none
        }
    }

    // MARK: - Фото/альбомы (мост к photosVM)

    func album(at index: Int) -> PhotoAlbum? {
        guard photosVM.albums.indices.contains(index) else { return nil }
        return photosVM.albums[index]
    }

    func coverURL(forAlbumAt index: Int) -> URL? {
        photosVM.coverURL(forAlbumAt: index)
    }

    func photoItem(at index: Int) -> Photo? {
        guard photosVM.photos.indices.contains(index) else { return nil }
        return photosVM.photos[index]
    }

    func allPhotos() -> [Photo] {
        photosVM.allPhotos()
    }

    func delete(photo: Photo) async {
        await photosVM.delete(photo: photo)
    }

    func addToSaved(photo: Photo) async {
        await photosVM.addToSaved(photo: photo)
    }

    // MARK: - Посты (мост к postsVM)

    func post(section: Int, item: Int) -> MyPost? {
        guard section == 1 else { return nil }
        let index = item - 1
        return postsVM.post(at: index)
    }

    func update(post: MyPost) async {
        await postsVM.update(post)
    }

    func indexOfPost(with id: String) -> Int? {
        postsVM.indexOfPost(with: id)
    }

    func toggleExpandedForPost(at item: Int) {
        postsVM.toggleExpanded(at: item)
    }

    @discardableResult
    func toggleLikeForPost(at item: Int) async -> (isLiked: Bool, likes: Int)? {
        await postsVM.toggleLike(at: item)
    }

    func incrementViewsForPost(at item: Int) async -> Int? {
        await postsVM.incrementViews(at: item)
    }

    func addPostToFavorites(at item: Int) async {
        await postsVM.toggleFavorite(at: item)
    }

    func deletePost(at index: Int) async {
        await postsVM.delete(at: index)
    }

    func insert(post: MyPost, at item: Int) {
        postsVM.insert(post, at: item)
    }
    
    func addPostToWall(at item: Int) async {
        await postsVM.addPostToWall(at: item)
    }
    
    func publish(post: MyPost) async {
       await postsVM.publish(post)
   }

    // MARK: - Аватар/обложка (мост к headerVM)

    func setAvatar(from photo: Photo) async {
        await headerVM.setAvatar(from: photo)
    }

    func setCover(from photo: Photo) async {
        await headerVM.setCover(from: photo)
    }
    
    /// Загружает фото из  альбома .profile (ипользуется для просмотра фото профиля по тапу на аватар, когда нет активной story). Возвращает список фото и индекс текущего, с которого начинать просмотр.
    func profileAlbumPhotosForAvatarTap() async -> (photos: [Photo], startIndex: Int)? {
        do {
            let photos = try await photosVM.loadProfileAlbumPhotos()
            guard !photos.isEmpty else { return nil }

            let avatarURL = headerVM.avatarURL
            let startIndex: Int

            if let avatarURL,
               let idx = photos.firstIndex(where: { $0.url == avatarURL }) {
                startIndex = idx
            } else {
                startIndex = 0
            }
            return (photos, startIndex)
        } catch {
            onError?(AppError.profileLoadingFailed)
            return nil
        }
    }
}
