import UIKit

/// Экран "Лента": сторисы + посты.
/// Работает поверх MainFeedViewModel, который инкапсулирует два под‑VM:
/// 1.  FeedStoriesViewModel
/// 2.  FeedPostsViewModel
@MainActor
final class FeedCollectionViewController: UICollectionViewController {

    /// Локальные секции контроллера: header + секции из MainFeedViewModel.
    private enum Section: Int, CaseIterable {
        case header = 0
        case stories = 1
        case posts   = 2
    }
    
    weak var coordinator: FeedCoordinator?
    private let viewModel: MainFeedViewModel

    /// Индекс сторис, которую нужно отметить просмотренной после возврата с экрана просмотра сторис.
    private var pendingViewedStoryIndex: Int?

    /// Pull‑to‑refresh для полного обновления ленты.
    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
        return control
    }()

    init(viewModel: MainFeedViewModel) {
        self.viewModel = viewModel
        super.init(collectionViewLayout: Self.createFeedLayout())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
        bindViewModel()
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)

        // При возврате с экрана просмотра сторис — пометить её как просмотренную и точечно перерисовываем нужную ячейку
        if let idx = pendingViewedStoryIndex {
            pendingViewedStoryIndex = nil

            viewModel.markStoryViewed(
                in: MainFeedViewModel.Section.stories.rawValue,
                itemIndex: idx
            )

            let ip = IndexPath(item: idx, section: Section.stories.rawValue)

            // без анимации, чтобы не было миганий
            UIView.performWithoutAnimation {
                collectionView.reloadItems(at: [ip])
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupCollectionView() {
        collectionView.backgroundColor = .appBackground

        // Регистрация ячеек постов
        collectionView.register(
            PostCollectionViewCell.self,
            forCellWithReuseIdentifier: PostCollectionViewCell.reuseId
        )

        // Регистрация ячеек сторис
        collectionView.register(
            StoryCollectionViewCell.self,
            forCellWithReuseIdentifier: StoryCollectionViewCell.reuseId
        )

        // Регистрация заголовка для секции header
        collectionView.register(
            TitleHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: TitleHeaderView.reuseId
        )

        collectionView.refreshControl = refreshControl
    }
    
    /// Создание композиционного layout для ленты:
    /// - секция header с небольшим заголовком "Главная"
    /// - горизонтальная секция сторис
    /// - вертикальная секция постов
    static func createFeedLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, _ in
            guard let section = Section(rawValue: sectionIndex) else { return nil }

            switch section {

            case .header:
                // Секция, содержащая только header (supplementary), без ячеек.
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(1)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = itemSize
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: groupSize,
                    subitems: [item]
                )

                let section = NSCollectionLayoutSection(group: group)

                let headerSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(35)
                )
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )

                section.boundarySupplementaryItems = [header]
                section.contentInsets = .init(top: 6, leading: 16, bottom: 0, trailing: 0)
                return section

            case .stories:
                // Горизонтальная лента сторис.
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .absolute(80),
                    heightDimension: .absolute(110)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .estimated(80),
                    heightDimension: .absolute(110)
                )
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitems: [item]
                )

                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.interGroupSpacing = 8
                section.contentInsets = .init(top: 4, leading: 8, bottom: 8, trailing: 8)
                return section

            case .posts:
                // Вертикальная лента постов с динамической высотой ячейки.
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(140)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(140)
                )
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: groupSize,
                    subitems: [item]
                )

                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 0
                section.contentInsets = .init(top: 0, leading: 0, bottom: 8, trailing: 0)
                return section
            }
        }
        return layout
    }

    private func bindViewModel() {
        viewModel.onReloadAll = { [weak self] in
            guard let self else { return }
            UIView.performWithoutAnimation {
                self.collectionView.reloadData()
            }
        }

        // Точечные обновления по индексам внутри секций VM.
        viewModel.onItemsUpdated = { [weak self] section, indices in
            guard let self else { return }

            switch section {
            case .stories:
                let controllerSection = Section.stories.rawValue

                // Сверить количество элементов до и после
                let newCount = self.viewModel.numberOfItems(
                    in: MainFeedViewModel.Section.stories.rawValue
                )
                let oldCount = self.collectionView.numberOfItems(inSection: controllerSection)

                // Если количество изменилось - перезагрузить всю секцию
                guard oldCount == newCount else {
                    UIView.performWithoutAnimation {
                        self.collectionView.reloadSections(IndexSet(integer: controllerSection))
                    }
                    return
                }

                // Иначе точечно перерисовать нужные ячейки
                let indexPaths = indices.map { IndexPath(item: $0, section: controllerSection) }
                UIView.performWithoutAnimation {
                    self.collectionView.reloadItems(at: indexPaths)
                }

            case .posts:
                let controllerSection = Section.posts.rawValue

                let newCount = self.viewModel.numberOfItems(
                    in: MainFeedViewModel.Section.posts.rawValue
                )
                let oldCount = self.collectionView.numberOfItems(inSection: controllerSection)

                guard oldCount == newCount else {
                    UIView.performWithoutAnimation {
                        self.collectionView.reloadSections(IndexSet(integer: controllerSection))
                    }
                    return
                }

                // Если количество совпадает — обновить только видимые ячейки
                for index in indices {
                    let indexPath = IndexPath(item: index, section: controllerSection)

                    guard
                        let cell = self.collectionView.cellForItem(at: indexPath)
                            as? PostCollectionViewCell
                    else { continue }

                    let post = self.viewModel.post(at: index)

                    // Локально обновить нужные части UI, не вызывая полный configure
                    cell.updateLikeState(isLiked: post.isLiked, likes: post.likes)
                    cell.updateViewsCount(post.views)
                    cell.configureMenu(
                        isFavorite: post.isFavorite,
                        favoriteTitle: nil,
                        onFavorite: nil,
                        onEdit: nil,
                        onDelete: nil
                    )
                }
            }
        }
    }

    /// Загрузка данных для ленты.
    private func loadData(completion: (() -> Void)? = nil) {
        Task { [weak self] in
            guard let self else { return }
            await viewModel.load()
            completion?()
        }
    }

    /// Обработчик pull‑to‑refresh.
    @objc private func handleRefresh(_ sender: UIRefreshControl) {
        loadData { [weak sender] in
            sender?.endRefreshing()
        }
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // header + секции VM (stories + posts)
        return 1 + viewModel.numberOfSections()
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        guard let sec = Section(rawValue: section) else { return 0 }

        switch sec {
        case .header:
            return 0

        case .stories:
            return viewModel.numberOfItems(
                in: MainFeedViewModel.Section.stories.rawValue
            )

        case .posts:
            return viewModel.numberOfItems(
                in: MainFeedViewModel.Section.posts.rawValue
            )
        }
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            return UICollectionViewCell()
        }

        switch section {
        case .header:
            return UICollectionViewCell()

        case .stories:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: StoryCollectionViewCell.reuseId,
                for: indexPath
            ) as! StoryCollectionViewCell

            let story = viewModel.story(at: indexPath.item)
            cell.configure(with: story)
            return cell

        case .posts:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PostCollectionViewCell.reuseId,
                for: indexPath
            ) as? PostCollectionViewCell else {
                return UICollectionViewCell()
            }

            let post = viewModel.post(at: indexPath.item)
            let currentUser = viewModel.currentUser

            cell.delegate = self
            cell.configure(with: post, user: currentUser)

            // Меню "ещё" с обработчиком изменения избранного
            cell.configureMenu(
                isFavorite: post.isFavorite,
                favoriteTitle: nil,
                onFavorite: { [weak self, weak cell] in
                    guard
                        let self,
                        let cell,
                        let currentIndexPath = self.collectionView.indexPath(for: cell),
                        let section = Section(rawValue: currentIndexPath.section),
                        section == .posts
                    else { return }

                    // Переключить избранное и пере‑конфигурировать меню
                    Task { @MainActor in
                        await self.viewModel.toggleFavorite(at: currentIndexPath.item)

                        let updatedPost = self.viewModel.post(at: currentIndexPath.item)

                        cell.configureMenu(
                            isFavorite: updatedPost.isFavorite,
                            favoriteTitle: nil,
                            onFavorite: { [weak self, weak cell] in
                                guard let self, let cell else { return }

                                guard
                                    let idx = self.collectionView.indexPath(for: cell),
                                    let section = Section(rawValue: idx.section),
                                    section == .posts
                                else { return }

                                Task { @MainActor in
                                    await self.viewModel.toggleFavorite(at: idx.item)
                                    let post = self.viewModel.post(at: idx.item)
                                    cell.configureMenu(
                                        isFavorite: post.isFavorite,
                                        favoriteTitle: nil,
                                        onFavorite: nil,
                                        onEdit: nil,
                                        onDelete: nil
                                    )
                                }
                            },
                            onEdit: nil,
                            onDelete: nil
                        )
                    }
                },
                onEdit: nil,
                onDelete: nil
            )

            return cell
        }
    }

    // MARK: - Supplementary views

    override func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard
            kind == UICollectionView.elementKindSectionHeader,
            let section = Section(rawValue: indexPath.section)
        else {
            return UICollectionReusableView()
        }

        switch section {
        case .header:
            // Заголовок "Главная" для верхней секции
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: TitleHeaderView.reuseId,
                for: indexPath
            ) as! TitleHeaderView
            header.configurePrimary(title: "Главная")
            return header

        default:
            return UICollectionReusableView()
        }
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard let section = Section(rawValue: indexPath.section) else { return }

        switch section {
        case .posts:
            break

        case .stories:
            // Запоминить индекс сторис, чтобы после возврата пометить её просмотренной
            pendingViewedStoryIndex = indexPath.item
            let story = viewModel.story(at: indexPath.item)

            // Переход в экран просмотра сторис
            coordinator?.present(.storyViewer(story: story))

        case .header:
            break
        }
    }
}

// MARK: - PostCollectionViewCellDelegate

extension FeedCollectionViewController: PostCollectionViewCellDelegate {

    /// Обработка нажатия "ещё" (развернуть/свернуть текст поста).
    func postCellDidTapMore(_ cell: PostCollectionViewCell) {
        guard
            let indexPath = collectionView.indexPath(for: cell),
            let section = Section(rawValue: indexPath.section),
            section == .posts
        else { return }

        _ = viewModel.post(at: indexPath.item).isExpanded

        // Изменить состояние "развёрнут / свернут" в VM
        viewModel.toggleExpanded(at: indexPath.item)

        // Без анимации обновить layout конкретной ячейки и скроллим к её верху, чтобы текст после разворота был виден полностью.
        UIView.performWithoutAnimation {
            collectionView.performBatchUpdates({
                collectionView.reloadItems(at: [indexPath])
                collectionView.layoutIfNeeded()
            }, completion: { _ in
                self.collectionView.scrollToItem(
                    at: indexPath,
                    at: .top,
                    animated: false
                )
            })
        }
    }

    /// Обработка нажатия "лайк".
    func postCellDidTapLike(_ cell: PostCollectionViewCell) {
        guard
            let indexPath = collectionView.indexPath(for: cell),
            let section = Section(rawValue: indexPath.section),
            section == .posts
        else { return }

        Task { [weak self] in
            guard let self else { return }

            // Переключить лайк в VM/сервисе
            await viewModel.toggleLike(at: indexPath.item)

            // Если ячейка всё ещё на экране — обновить
            if let visibleCell = collectionView.cellForItem(at: indexPath)
                as? PostCollectionViewCell {
                let updated = viewModel.post(at: indexPath.item)
                visibleCell.updateLikeState(
                    isLiked: updated.isLiked,
                    likes: updated.likes
                )
            }
        }
    }

    /// Обработка нажатия "поделиться постом" (репост в стену).
    func postCellDidTapShare(_ cell: PostCollectionViewCell) {
        guard
            let indexPath = collectionView.indexPath(for: cell),
            let section = Section(rawValue: indexPath.section),
            section == .posts
        else { return }

        Task { [weak self] in
            await self?.viewModel.addPostToWall(at: indexPath.item)
        }
    }

    /// Обработка нажатия на картинку поста — открытие полноэкранного просмотрщика.
    func postCellDidTapImage(_ cell: PostCollectionViewCell) {
        guard
            let indexPath = collectionView.indexPath(for: cell),
            let section = Section(rawValue: indexPath.section),
            section == .posts
        else { return }

        // Увеличить счётчик просмотров
        Task { @MainActor in
            await viewModel.incrementViews(at: indexPath.item)
        }

        let post = viewModel.post(at: indexPath.item)

        // Проверяем валидность URL картинки
        guard
            let path = post.imagePath,
            !path.isEmpty,
            let url = URL(string: path)
        else {
            AppLogger.debug(
                "[FEED] postCellDidTapImage: no valid image url for post \(post.id)"
            )
            return
        }

        let photo = Photo(id: post.id, url: url, albumId: nil)

        // Открыть viewer с одним фото
        coordinator?.present(
            .photoViewer(
                photos: [photo],
                startIndex: 0,
                showAddToSaved: true,
                viewInPost: true
            )
        )
    }
}
