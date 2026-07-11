import UIKit

/// Делегат экрана Фото. Используется, чтобы уведомить, что список фото/альбомов изменился (добавление/удаление и т.п.).
protocol PhotosViewControllerDelegate: AnyObject {
    /// Вызывается, когда содержимое альбомов/фото изменилось..
    func photosDidChange()
}

/// Экран Фото:  В режиме `.main` показывает табы `Фото/Альбомы`.  В режиме `.album`- фото конкретного альбома.
final class PhotosViewController: UICollectionViewController {

    /// Секции коллекции в режиме `.main`.
    enum Section: Int, CaseIterable {
        case tabsHeader   // секция с заголовком-таба (хедер с CapsuleTabsControl)
        case content      // секция с контентом: либо альбомы, либо фото
    }

    /// Активный таб в режиме `.main`.
    enum Tab {
        case photos
        case albums
    }

    weak var coordinator: ProfileCoordinator?
    weak var delegate: PhotosViewControllerDelegate?

    private let viewModel: PhotosViewModel

    private let refreshControl = UIRefreshControl()

    /// Текущий выбранный таб..
    private var currentTab: Tab = .photos

    /// Флаг, чтобы не вызывать `viewModel.load()` каждый раз при появлении.
    private var didInitialLoad = false

    init(viewModel: PhotosViewModel) {
        self.viewModel = viewModel

        let baseLayout = UICollectionViewFlowLayout()
        super.init(collectionViewLayout: baseLayout)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = .appBackground
        
        setupNavigationBar()
        setupCollectionView()
        setupRefreshControlIfNeeded()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

//        // Гарантируем, что навбар виден (важно, если профиль где-то его скрывает).
//        coordinator?.navController.setNavigationBarHidden(false, animated: animated)

        // Первичная загрузка данных
        Task { [weak self] in
            guard let self else { return }

            if !didInitialLoad {
                didInitialLoad = true
                await viewModel.load()

                await MainActor.run {
                    // Подстройка layout под текущий режим/таб и перезагрузка данных
                    self.collectionView.setCollectionViewLayout(
                        self.makeCurrentLayout(),
                        animated: false
                    )
                    self.collectionView.reloadData()
                }
            }
        }
    }

    /// Настройка навигационного бара (заголовок).
    private func setupNavigationBar() {
        switch viewModel.mode {
        case .main:
            title = "Фото"
        case .album(let album):
            // Если у альбома нет названия — fallback к "Фото".
            title = album.title.isEmpty ? "Фото" : album.title
        }
    }

    /// Регистрация ячеек и хедеров коллекции.
    private func setupCollectionView() {
        collectionView.register(
            AlbumCell.self,
            forCellWithReuseIdentifier: AlbumCell.reuseId
        )
        collectionView.register(
            PhotoCell.self,
            forCellWithReuseIdentifier: PhotoCell.reuseId
        )
        collectionView.register(
            PhotosTabsHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: PhotosTabsHeaderView.reuseId
        )
    }

    /// Добавление pull‑to‑refresh.
    private func setupRefreshControlIfNeeded() {
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
    }

    private func bindViewModel() {
        viewModel.onChanged = { [weak self] in
            guard let self else { return }

            if case .main = self.viewModel.mode {
                // В .main только контентная секция — табы остаются на месте
                self.reloadForCurrentTab()
            } else {
                // В .album полная перезагрузка
                self.collectionView.reloadData()
            }
        }

        viewModel.onError = { [weak self] error in
            guard let self else { return }

            self.refreshControl.endRefreshing()
            self.showAlert(message: error.localizedDescription)
        }
    }

    /// Обработка pull‑to‑refresh (перезагрузка данных).
    @objc private func handleRefresh() {
        Task { [weak self] in
            guard let self else { return }

            await self.viewModel.load(force: true)

            await MainActor.run {
                self.refreshControl.endRefreshing()
            }
        }
    }
}

// MARK: - Layout

extension PhotosViewController {

    /// Фабрика compositional‑layout’а: `currentMode` и `currentTab` -  замыкания, чтобы layout мог узнавать актуальное состояние при инвалидации/перестроении.
    static func makeLayout(
        currentMode: @escaping () -> PhotosScreenMode,
        currentTab: @escaping () -> Tab
    ) -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in
            let mode = currentMode()

            switch mode {

            // Режим .album: только фотографии, без табов и секций
            case .album:
                // Одна секция с гридом 3xN.
                guard sectionIndex == 0 else { return nil }

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
                section.contentInsets = .init(top: 0, leading: 0, bottom: 8, trailing: 0)
                return section

            // Режим .main: табы + контент
            case .main:
                guard let section = Section(rawValue: sectionIndex) else { return nil }

                switch section {
                // заголовок с табами
                case .tabsHeader:
                    // здесь только хедер
                    let itemSize = NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .absolute(1)
                    )
                    let item = NSCollectionLayoutItem(layoutSize: itemSize)

                    let groupSize = NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .absolute(1)
                    )
                    let group = NSCollectionLayoutGroup.horizontal(
                        layoutSize: groupSize,
                        subitems: [item]
                    )

                    let section = NSCollectionLayoutSection(group: group)

                    let headerSize = NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .absolute(40)
                    )
                    let header = NSCollectionLayoutBoundarySupplementaryItem(
                        layoutSize: headerSize,
                        elementKind: UICollectionView.elementKindSectionHeader,
                        alignment: .top
                    )
                    section.boundarySupplementaryItems = [header]
                    return section

                // контент (альбомы/фото)
                case .content:
                    switch currentTab() {

                    // альбомы — по 2 в строку
                    case .albums:
                        let groupSize = NSCollectionLayoutSize(
                            widthDimension: .fractionalWidth(1.0),
                            heightDimension: .fractionalWidth(0.35)
                        )

                        // группа = 2 айтема по горизонтали
                        let group = NSCollectionLayoutGroup.horizontal(
                            layoutSize: groupSize,
                            subitem: {
                                let itemSize = NSCollectionLayoutSize(
                                    widthDimension: .fractionalWidth(0.5),
                                    heightDimension: .fractionalHeight(1.0)
                                )
                                return NSCollectionLayoutItem(layoutSize: itemSize)
                            }(),
                            count: 2
                        )
                        group.interItemSpacing = .fixed(4)

                        let section = NSCollectionLayoutSection(group: group)
                        section.interGroupSpacing = 4
                        section.contentInsets = .init(top: 4, leading: 4, bottom: 4, trailing: 4)
                        return section

                    // фото — грид 3xN.
                    case .photos:
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
                        section.contentInsets = .init(top: 1, leading: 1, bottom: 1, trailing: 1)
                        return section
                    }
                }
            }
        }
    }

    /// Текущий layout, основанный на состоянии viewModel и активного таба.
    private func makeCurrentLayout() -> UICollectionViewLayout {
        PhotosViewController.makeLayout(
            currentMode: { [weak self] in self?.viewModel.mode ?? .main },
            currentTab: { [weak self] in self?.currentTab ?? .photos }
        )
    }

    /// Перезагрузка  контентной секции (в режиме `.main`),  чтобы не мигал хедер с табами.
    private func reloadForCurrentTab() {
        UIView.performWithoutAnimation {
            if case .main = viewModel.mode {
                collectionView.reloadSections(
                    IndexSet(integer: Section.content.rawValue)
                )
            } else {
                collectionView.reloadData()
            }
        }
    }
}

// MARK: - DataSource / Delegate

extension PhotosViewController {

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        switch viewModel.mode {
        case .album:
            // В режиме альбома - одна секция с фото
            return 1
        case .main:
            // tabsHeader + content
            return 2
        }
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        switch viewModel.mode {
        case .album:
            return viewModel.photos.count

        case .main:
            guard let photosSection = Section(rawValue: section) else { return 0 }

            switch photosSection {
            case .tabsHeader:
                // секция без айтемов — только хедер
                return 0

            case .content:
                switch currentTab {
                case .photos:
                    return viewModel.photos.count
                case .albums:
                    return viewModel.albums.count
                }
            }
        }
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch viewModel.mode {
        case .album:
            // В режиме альбома всегда фото
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PhotoCell.reuseId,
                for: indexPath
            ) as! PhotoCell
            let photo = viewModel.photos[indexPath.item]
            cell.configure(with: photo.url)
            return cell

        case .main:
            guard let section = Section(rawValue: indexPath.section) else {
                return UICollectionViewCell()
            }

            switch section {
            case .tabsHeader:
                // в этой секции нет ячеек
                return UICollectionViewCell()

            case .content:
                switch currentTab {
                case .albums:
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: AlbumCell.reuseId,
                        for: indexPath
                    ) as! AlbumCell

                    let album = viewModel.albums[indexPath.item]
                    let coverURL = viewModel.coverURL(forAlbumAt: indexPath.item)
                    cell.configure(with: album, coverURL: coverURL)
                    return cell

                case .photos:
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: PhotoCell.reuseId,
                        for: indexPath
                    ) as! PhotoCell

                    let photo = viewModel.photos[indexPath.item]
                    cell.configure(with: photo.url)
                    return cell
                }
            }
        }
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        switch viewModel.mode {

        case .album(let album):
            // Открываем вьюер фото для конкретного альбома
            let start = indexPath.item
            // Для альбома "Сохранённые" не показываем пункт "Добавить в сохранённые"
            let showAddToSaved = (album.type != .saved)

            coordinator?.showPhotoViewer(
                photos: viewModel.photos,
                startIndex: start,
                delegate: self,
                showAddToSaved: showAddToSaved
            )

        case .main:
            guard let section = Section(rawValue: indexPath.section) else { return }

            switch section {
            case .tabsHeader:
                // Тапы по хедеру здесь не обрабатываются
                break

            case .content:
                switch currentTab {
                case .albums:
                    // Переход в режим просмотра фото альбома
                    let album = viewModel.albums[indexPath.item]
                    coordinator?.showAlbumPhotos(album: album, delegate: self)

                case .photos:
                    // Открываем полноэкранный просмотр фото
                    let start = indexPath.item
                    coordinator?.showPhotoViewer(
                        photos: viewModel.photos,
                        startIndex: start,
                        delegate: self,
                        showAddToSaved: true
                    )
                }
            }
        }
    }

    // MARK: - Header (табы)

    override func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {

        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }

        switch viewModel.mode {
        case .album:
            // В режиме альбома хедеров нет
            return UICollectionReusableView()

        case .main:
            guard let section = Section(rawValue: indexPath.section) else {
                return UICollectionReusableView()
            }

            switch section {
            case .tabsHeader:
                let header = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: PhotosTabsHeaderView.reuseId,
                    for: indexPath
                ) as! PhotosTabsHeaderView

                // Синхронизируем выбранный таб
                header.configure(selectedTab: currentTab)

                header.onTabChanged = { [weak self] tab in
                    guard let self else { return }
                    // Если таб не изменился — ничего не делаем
                    if self.currentTab == tab { return }

                    self.currentTab = tab
                    self.reloadForCurrentTab()
                }

                return header

            case .content:
                return UICollectionReusableView()
            }
        }
    }
}

// MARK: - PhotoViewerViewControllerDelegate

extension PhotosViewController: PhotoViewerViewControllerDelegate {
    /// Установить фотографией профиляЮ
    func photoViewer(_ vc: PhotosViewerViewController, didChooseAvatarFrom photo: Photo) {
        Task { @MainActor [weak self] in
            await self?.viewModel.setAvatar(from: photo)
        }
    }
    
    /// Установить обложкой профиля.
    func photoViewer(_ vc: PhotosViewerViewController, didChooseCoverFrom photo: Photo) {
        Task { @MainActor [weak self] in
            await self?.viewModel.setCover(from: photo)
        }
    }
    
    /// Добавить в альбом "Сохраненные".
    func photoViewer(_ vc: PhotosViewerViewController, didAddToSaved photo: Photo) {
        Task { @MainActor [weak self] in
            await self?.viewModel.addToSaved(photo: photo)
           
        }
    }
    
    /// Удалить фото из альбома + уведомить родителя об изменениях в режиме альбома.
    func photoViewer(_ vc: PhotosViewerViewController, didDelete photo: Photo) {
        Task { @MainActor [weak self] in
            guard let self else { return }

            await self.viewModel.delete(photo: photo)

            if case .album = self.viewModel.mode {
                // Сообщить родителю, что контент изменился
                self.delegate?.photosDidChange()
            }
            self.coordinator?.closeVC()
        }
    }
}

// MARK: - PhotosViewControllerDelegate (для вложенных PhotosVC)

extension PhotosViewController: PhotosViewControllerDelegate {

    /// Вызывается дочерним PhotosVC ( экраном альбома), чтобы сообщить, что фото/альбомы изменились.
    func photosDidChange() {
        Task { [weak self] in
            guard let self else { return }
            // Форс‑перезагрузка данных с сервера
            await self.viewModel.load(force: true)

            await MainActor.run {
                if case .main = self.viewModel.mode {
                    self.reloadForCurrentTab()
                } else {
                    self.collectionView.reloadData()
                }
            }
            // Пробрасить событие наверх (в профиль)
            self.delegate?.photosDidChange()
        }
    }
}
