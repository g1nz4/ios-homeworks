import UIKit
import PhotosUI
import StorageService

/// Основной экран профиля: хедер, капсулы: "Друзья" и "Опубликовать пост"; табы (.main/.posts/.photos/.music), посты, альбомы, фотографии, музыка, сториз, кнопка публикации...
@MainActor
final class ProfileViewController: UICollectionViewController {
    
    weak var coordinator: ProfileCoordinator?
    
    private let viewModel: ProfileViewModel
    private let collectionHandler: ProfileCollectionHandler
    
    private let refreshControl = UIRefreshControl()
    private let collapsingTitleLabel = UILabel()
    
    /// Всплывающая капсульная кнопка ("В раздел") для фото‑таба.
    private let floatingCapsuleButton = FloatingCapsuleButton()
    private var floatingCapsuleButtonBottomConstraint: NSLayoutConstraint?
    
    private var topSafeInset: CGFloat = 0
    
    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        self.collectionHandler = ProfileCollectionHandler(viewModel: viewModel)
        
        // Инициализация layout с провайдером текущего таба
        let layout = ProfileViewController.createLayout(
            currentTabProvider: { [weak viewModel] in
                viewModel?.currentTab ?? .main
            },
            topInset: 0
        )
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        setupPhotosFloatingButton()
        configureNavigationBarAppearance()
        setupNavigationBar()
        setupRefreshControl()
        bindHandler()
        bindViewModel()
        loadProfile()
        
        // Всплывающая кнопка показывается только на табе .photos.
        floatingCapsuleButton.alpha = viewModel.currentTab == .photos ? 1 : 0
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        let newInset = view.safeAreaInsets.top
        guard newInset != topSafeInset else { return }
        
        topSafeInset = newInset
        collectionHandler.updateTopInset(newInset)
        collectionView.layoutIfNeeded()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.bringSubviewToFront(floatingCapsuleButton)
    }
    
    /// Настройка  навигационной панели.
    private func setupNavigationBar() {
        collapsingTitleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        collapsingTitleLabel.textColor = .appPrimaryText
        collapsingTitleLabel.textAlignment = .center
        collapsingTitleLabel.alpha = 0
        navigationItem.titleView = collapsingTitleLabel
        
        let menuButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain,
            target: nil,
            action: nil
        )
        menuButton.menu = makeProfileMenu()
        menuButton.primaryAction = nil
        navigationItem.rightBarButtonItem = menuButton
    }
    
    /// Прозрачный навбар поверх контента.
    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.backgroundEffect = nil
        
        guard let navBar = navigationController?.navigationBar else { return }
        
        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.compactAppearance = appearance
        navBar.compactScrollEdgeAppearance = appearance
        
        navBar.isTranslucent = true
        navBar.setBackgroundImage(UIImage(), for: .default)
        navBar.shadowImage = UIImage()
        navBar.tintColor = .appPrimaryText
    }
    
    /// Контекстное меню профиля (редактирование, сториз, избранное, настройки, выход).
    private func makeProfileMenu() -> UIMenu {
        let editProfile = UIAction(
            title: "Редактировать профиль",
            image: UIImage(systemName: "pencil")
        ) { [weak self] _ in
            guard let self else { return }
            let currentUser = self.viewModel.currentUser
            self.coordinator?.present(.editProfile(currentUser))
        }
        
        let publishStory = UIAction(
            title: "Опубликовать историю",
            image: UIImage(systemName: "plus.circle")
        ) { [weak self] _ in
            self?.coordinator?.present(.createStory)
        }
        
        let favorites = UIAction(
            title: "Избранное",
            image: UIImage(systemName: "bookmark")
        ) { [weak self] _ in
            self?.coordinator?.present(.favorites)
        }
        
        let settings = UIAction(
            title: "Настройки",
            image: UIImage(systemName: "gearshape")
        ) { [weak self] _ in
            self?.coordinator?.present(.settings)
        }
        
        let logout = UIAction(
            title: "Выйти",
            image: UIImage(systemName: "rectangle.portrait.and.arrow.right"),
            attributes: .destructive
        ) { [weak self] _ in
            self?.coordinator?.didTapLogout()
        }
        
        return UIMenu(
            title: "",
            children: [editProfile, publishStory, favorites, settings, logout]
        )
    }
    
    /// Базовая настройка collectionView и регистрация ячеек/хедеров.
    private func setupCollectionView() {
        collectionView.backgroundColor = .appSecondaryBackground
        
        collectionView.register(
            PublishCapsuleCollectionViewCell.self,
            forCellWithReuseIdentifier: PublishCapsuleCollectionViewCell.reuseId
        )
        collectionView.register(
            FriendsCollectionViewCell.self,
            forCellWithReuseIdentifier: FriendsCollectionViewCell.reuseId
        )
        collectionView.register(
            PostCollectionViewCell.self,
            forCellWithReuseIdentifier: PostCollectionViewCell.reuseId
        )
        collectionView.register(
            AlbumCell.self,
            forCellWithReuseIdentifier: AlbumCell.reuseId
        )
        collectionView.register(
            PhotoCell.self,
            forCellWithReuseIdentifier: PhotoCell.reuseId
        )
        collectionView.register(
            ProfileHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ProfileHeaderView.reuseId
        )
        collectionView.register(
            ProfileTabsCell.self,
            forCellWithReuseIdentifier: ProfileTabsCell.reuseId
        )
        collectionView.register(
            ProfileSectionTitleView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ProfileSectionTitleView.reuseId
        )
        collectionView.register(
            EmptyMessageCell.self,
            forCellWithReuseIdentifier: EmptyMessageCell.reuseId
        )
    }
    
    /// Настройка pull-to-refresh для обновления профиля.
    private func setupRefreshControl() {
        refreshControl.tintColor = .appAccent
        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
    }
    
    /// Привязка dataSource и delegate коллекции к handler’у.
    private func bindHandler() {
        collectionView.dataSource = collectionHandler
        collectionView.delegate = collectionHandler
        collectionHandler.output = self
    }
    
    /// Настройка плавающей кнопки "В раздел" .
    private func setupPhotosFloatingButton() {
        floatingCapsuleButton.translatesAutoresizingMaskIntoConstraints = false
        floatingCapsuleButton.configure(title: "В раздел")
        floatingCapsuleButton.alpha = 0
        
        view.addSubview(floatingCapsuleButton)
        
        floatingCapsuleButtonBottomConstraint = floatingCapsuleButton.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -8
        )
        
        NSLayoutConstraint.activate([
            floatingCapsuleButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            floatingCapsuleButtonBottomConstraint!,
            floatingCapsuleButton.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        floatingCapsuleButton.addTarget(
            self,
            action: #selector(didTapPhotosFloatingButton),
            for: .touchUpInside
        )
    }
    
    /// Создаёт compositional layout для экрана профиля.
    private static func createLayout(
        currentTabProvider: @escaping () -> ProfileTab,
        topInset: CGFloat = 0
    ) -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, _ in
            let currentTab = currentTabProvider()
            
            switch sectionIndex {
            // ===== Section 0 — профиль (header + "Друзья"/"Опубликовать =====
            case 0:
                // Элемент — одна строка (friends/publish)
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(52)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                // Группа — вертикальная, 1 элемент в ширину, высота по содержимому
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(52)
                )
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: groupSize,
                    subitems: [item]
                )
                
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 8
                section.contentInsets = .init(top: 8, leading: 0, bottom: 8, trailing: 0)
                // Хедер профиля (ProfileHeaderView) с фиксированной высотой
                let baseHeaderHeight: CGFloat = 240
                
                let headerSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(baseHeaderHeight)
                )
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [header]
                return section
                
            // ===== Section 1 — табы + посты =====
            case 1:
                // Item — либо ячейка с табами, либо пост
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(44)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                // Группа — вертикальная, высота по содержимому
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(80)
                )
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: groupSize,
                    subitems: [item]
                )
                
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 0
                section.contentInsets = .zero
                // Декоративный фон для секции (скругления/цвет задаются в SectionBackgroundView)
                let background = NSCollectionLayoutDecorationItem.background(
                    elementKind: SectionBackgroundView.elementKind
                )
                background.contentInsets = .zero
                return section
                
            // ===== Section 2 — горизонтальная лента альбомов (только .photos) =====
            case 2:
                guard currentTab == .photos else { return nil }
                // Один альбом фиксированного размера
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .absolute(150),
                    heightDimension: .absolute(120)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .absolute(150),
                    heightDimension: .absolute(120)
                )
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitems: [item]
                )
                
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.interGroupSpacing = 6
                section.contentInsets = .init(top: 6, leading: 6, bottom: 6, trailing: 6)
                // Заголовок секции
                let headerSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(32)
                )
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [header]
                // Декоративный фон
                let background = NSCollectionLayoutDecorationItem.background(
                    elementKind: SectionBackgroundView.elementKind
                )
                background.contentInsets = .zero
                section.decorationItems = [background]
                return section
                
            // ===== Section 3 — грид фото по 3 в ряд (только .photos) =====
            case 3:
                guard currentTab == .photos else { return nil }
                // Item — одна фото‑ячейка, 1/3 ширины
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0 / 3.0),
                    heightDimension: .fractionalWidth(1.0 / 3.0)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = .init(top: 1, leading: 1, bottom: 1, trailing: 1)
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalWidth(1.0 / 3.0)
                )
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitems: [item]
                )
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = .init(top: 6, leading: 6, bottom: 6, trailing: 6)
                // Заголовок секции
                let headerSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(32)
                )
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [header]
                // Декоративный фон
                let background = NSCollectionLayoutDecorationItem.background(
                    elementKind: SectionBackgroundView.elementKind
                )
                background.contentInsets = .zero
                section.decorationItems = [background]
                return section
                
            default:
                return nil
            }
        }
        // Регистрирация декорационного view для фона в секциях
        layout.register(
            SectionBackgroundView.self,
            forDecorationViewOfKind: SectionBackgroundView.elementKind
        )
        
        return layout
    }
    
    /// Подписка на колбэки viewModel.
    private func bindViewModel() {
        // Обновление хедера
        viewModel.updateHeader = { [weak self] user in
            guard let self else { return }
            // Никнейм в навбаре: @nickname, если он есть
            let rawNickname = user.nickname?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let nick = rawNickname, !nick.isEmpty {
                self.collapsingTitleLabel.text = "@\(nick)"
                self.collapsingTitleLabel.isHidden = false
            } else {
                self.collapsingTitleLabel.text = nil
                self.collapsingTitleLabel.isHidden = true
            }
            
            self.collectionHandler.updateUser(user)
            // Перезагрузка данных без анимации, чтобы не мигал интерфейс
            UIView.performWithoutAnimation {
                self.collectionView.reloadData()
                self.collectionView.layoutIfNeeded()
            }
        }
        
        // Смена таба (main/posts/photos/music)
        viewModel.onTabChanged = { [weak self] in
            guard let self else { return }
            
            let beforeSections = self.collectionView.numberOfSections
            let afterSections = self.viewModel.numberOfSections()
            let currentTab = self.viewModel.currentTab
            
            UIView.performWithoutAnimation {
                let offset = self.collectionView.contentOffset
                
                if beforeSections != afterSections {
                    // Кол-во секций изменилось — перезагрузить всю коллекцию
                    self.collectionView.reloadData()
                } else {
                    // Секции совпали — обновлить только секцию с табами/постами
                    self.collectionView.reloadSections(IndexSet(integer: 1))
                }
                // Явная инвалидация layout, чтобы он пересчитал размеры
                self.collectionView.collectionViewLayout.invalidateLayout()
                self.collectionView.layoutIfNeeded()
                self.collectionView.setContentOffset(offset, animated: false)
            }
            
            let isPhotos = (currentTab == .photos)
            self.floatingCapsuleButton.alpha = isPhotos ? 1 : 0
        }
        
        // Обновление данных фото (только если активен таб .photos)
        viewModel.onPhotosChanged = { [weak self] in
            guard let self else { return }
            guard self.viewModel.currentTab == .photos else { return }
            
            UIView.performWithoutAnimation {
                self.collectionView.reloadData()
                self.collectionView.layoutIfNeeded()
            }
        }
        
        // Флаг наличия сторис (меняет хедер и бордеры аватара)
        viewModel.onStoryFlagChanged = { [weak self] hasStory in
            self?.setHasStory(hasStory)
        }
        
        // Статус обновления (pull-to-refresh)
        viewModel.onRefreshingChanged = { [weak self] isRefreshing in
            guard let self else { return }
            if !isRefreshing {
                self.refreshControl.endRefreshing()
            }
        }
        
        // Ошибки загрузки/обновления
        viewModel.onError = { [weak self] error in
            guard let self else { return }
            self.refreshControl.endRefreshing()
            self.showAlert(message: error.localizedDescription)
        }
        
        // Устанавлить исходный флаг сторис
        setHasStory(viewModel.hasStory)
        
        if let user = viewModel.headerUser {
            viewModel.updateHeader?(user)
        }
    }
    
    /// Первичная загрузка профиля.
    private func loadProfile() {
        Task { [weak self] in
            guard let self else { return }
            
            await self.viewModel.reloadProfile()
            
            UIView.performWithoutAnimation {
                let postsSection = 1
                if self.collectionView.numberOfSections > postsSection {
                    self.collectionView.reloadSections(IndexSet(integer: postsSection))
                } else {
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    // MARK: - Public (для координатора)
    /// Обновить флаг наличия сторис  (handler + текущий хедер, если виден)
    func setHasStory(_ value: Bool) {
        collectionHandler.updateHasStory(value)
        
        if let header = collectionView.supplementaryView(
            forElementKind: UICollectionView.elementKindSectionHeader,
            at: IndexPath(item: 0, section: 0)
        ) as? ProfileHeaderView {
            header.setHasStory(value)
        } else {
            collectionView.reloadData()
        }
    }
    
    /// Тап по плавающей кнопке "В раздел".
    @objc private func didTapPhotosFloatingButton() {
        coordinator?.present(.photos)
    }
    
    @objc private func didPullToRefresh() {
        Task { [weak self] in
            await self?.viewModel.reloadProfile(isPullToRefresh: true)
        }
    }
}

// MARK: - ProfileCollectionHandlerOutput

extension ProfileViewController: ProfileCollectionHandlerOutput {

    /// Скролл профиля — анимация появления никнейма в навбаре.
    func didScrollProfile(offsetY: CGFloat) {
        let start: CGFloat = 40
        let end: CGFloat = 140

        let progress = max(0, min((offsetY - start) / (end - start), 1))
        collapsingTitleLabel.alpha = progress
    }

    func didSelectFriends() {
        coordinator?.present(.friends)
    }

    func didSelectPublish() {
        coordinator?.present(.publishPost)
    }

    func didSelectAlbum(_ album: PhotoAlbum) {
        coordinator?.showAlbumPhotos(album: album, delegate: coordinator)
    }

    func didSelectPhoto(at index: Int, allPhotos: [Photo]) {
        coordinator?.showPhotoViewer(photos: allPhotos, startIndex: index)
    }

    /// Тап по аватару, если есть сторис.
    func didSelectStory(hasStory: Bool) {
        if hasStory {
            coordinator?.present(.storyViewer)
        } else {
            didTapAvatarWithoutStory()
        }
    }
    
    // MARK: Работа с постами (редактирование/удаление/лайки/просмотры)

    func didTapEditPost(_ post: MyPost) {
        coordinator?.present(.editPost(post))
    }

    func didTapDeletePost(at index: Int) {
        let postsSection = 1

        Task { @MainActor in
            let rowsBefore = viewModel.numberOfRows(in: postsSection)

            await viewModel.deletePost(at: index)

            let rowsAfter = viewModel.numberOfRows(in: postsSection)

            UIView.performWithoutAnimation {
                if rowsBefore == rowsAfter {
                    let indexPath = IndexPath(item: index + 1, section: postsSection)
                    self.collectionView.performBatchUpdates({
                        self.collectionView.deleteItems(at: [indexPath])
                    }, completion: nil)
                } else {
                    self.collectionView.reloadSections(IndexSet(integer: postsSection))
                }
                self.collectionView.layoutIfNeeded()
            }
        }
    }

    func didToggleFavorite(postIndex: Int, cell: PostCollectionViewCell) {
        let indexPath = IndexPath(item: postIndex + 1, section: 1)

        Task { @MainActor in
            await viewModel.addPostToFavorites(at: postIndex)

            guard let updatedPost = viewModel.post(
                section: indexPath.section,
                item: indexPath.item
            ) else { return }

            cell.configureMenu(
                isFavorite: updatedPost.isFavorite,
                onFavorite: { [weak self, weak cell] in
                    guard let self, let cell else { return }
                    self.didToggleFavorite(postIndex: postIndex, cell: cell)
                },
                onEdit: { [weak self] in
                    guard
                        let self,
                        let post = self.viewModel.post(
                            section: indexPath.section,
                            item: indexPath.item
                        )
                    else { return }
                    self.didTapEditPost(post)
                },
                onDelete: { [weak self] in
                    self?.didTapDeletePost(at: postIndex)
                }
            )
        }
    }

    func incrementViewsForPost(at index: Int, cell: PostCollectionViewCell) {
        Task { [weak self, weak cell] in
            guard let self, let cell else { return }

            if let newViews = await self.viewModel.incrementViewsForPost(at: index) {
                cell.updateViewsCount(newViews)
            }
        }
    }

    func toggleLikeForPost(at index: Int, cell: PostCollectionViewCell) {
        Task { [weak self, weak cell] in
            guard let self, let cell else { return }

            if let newState = await self.viewModel.toggleLikeForPost(at: index) {
                await MainActor.run {
                    cell.updateLikeState(
                        isLiked: newState.isLiked,
                        likes: newState.likes
                    )
                }
            }
        }
    }

    /// Тап по аватару, если сторис нет — открываем viewer с фото из альбома профиля.
    func didTapAvatarWithoutStory() {
        Task { [weak self] in
            guard let self else { return }

            if let result = await self.viewModel.profileAlbumPhotosForAvatarTap() {
                self.coordinator?.showPhotoViewer(
                    photos: result.photos,
                    startIndex: result.startIndex
                )
            } else {
                AppLogger.debug(
                    "[PROFILE VC] profileAlbumPhotosForAvatarTap returned nil (avatar tap)"
                )
            }
        }
    }

    func didTapMoreInfo() {
        coordinator?.present(.info)
    }
}

// MARK: - Helpers: обновление Item-ов коллекции без анимации

private extension ProfileViewController {

    /// Перезагрузить указанные item'ы без анимации (чтобы избежать "мигания").
    func reloadItemsWithoutAnimation(_ indexPaths: [IndexPath]) {
        guard !indexPaths.isEmpty else { return }

        UIView.performWithoutAnimation {
            collectionView.reloadItems(at: indexPaths)
            collectionView.layoutIfNeeded()
        }
    }

    /// Вставить новые item'ы без анимации.
    func insertItemsWithoutAnimation(_ indexPaths: [IndexPath]) {
        guard !indexPaths.isEmpty else { return }

        UIView.performWithoutAnimation {
            collectionView.performBatchUpdates({
                collectionView.insertItems(at: indexPaths)
            }, completion: nil)
            collectionView.layoutIfNeeded()
        }
    }
}

// MARK: - PublishPostViewControllerDelegate

extension ProfileViewController: PublishPostViewControllerDelegate {

    func publishPostViewController(_ vc: PublishPostViewController, didCreate post: MyPost) {
        let postsSection = 1
        let rowsBefore = viewModel.numberOfRows(in: postsSection)

        viewModel.insert(post: post, at: 0)

        if viewModel.currentTab == .main {
            let rowsAfter = viewModel.numberOfRows(in: postsSection)

            if rowsAfter == rowsBefore + 1 {
                // Добавился ровно 1 пост — аккуратно вставить item
                let indexPath = IndexPath(item: 1, section: postsSection)
                insertItemsWithoutAnimation([indexPath])
            } else {
                // Кол-во строк изменилось по-другому (если была заглушка)
                UIView.performWithoutAnimation {
                    if collectionView.numberOfSections > postsSection {
                        collectionView.reloadSections(IndexSet(integer: postsSection))
                    } else {
                        collectionView.reloadData()
                    }
                    collectionView.layoutIfNeeded()
                }
            }
        } else {
            // Если активен другой таб, просто обновить данные
            UIView.performWithoutAnimation {
                if collectionView.numberOfSections > postsSection {
                    collectionView.reloadSections(IndexSet(integer: postsSection))
                } else {
                    collectionView.reloadData()
                }
                collectionView.layoutIfNeeded()
            }
        }
    }

    func publishPostViewController(_ vc: PublishPostViewController, didEdit post: MyPost) {
        Task { @MainActor in
            await viewModel.update(post: post)

            if let index = viewModel.indexOfPost(with: post.id) {
                let indexPath = IndexPath(item: index + 1, section: 1)
                self.reloadItemsWithoutAnimation([indexPath])
            }
        }
    }
}

// MARK: - FavoritesDelegate

extension ProfileViewController: FavoritesDelegate {

    /// Пост удален из избранного в другом экране — обновляет локальный список.
    func favoritesDidRemoveFromFavorites(postId: String) {
        viewModel.setFavorite(false, forPostId: postId)

        if let index = viewModel.indexOfPost(with: postId) {
            let indexPath = IndexPath(item: index + 1, section: 1)
            reloadItemsWithoutAnimation([indexPath])
        }
    }

    func favoritesDidUpdate(post: MyPost) {
        viewModel.applyUpdatedPostFromFavorites(post)

        if let index = viewModel.indexOfPost(with: post.id) {
            let indexPath = IndexPath(item: index + 1, section: 1)
            reloadItemsWithoutAnimation([indexPath])
        }
    }
}
