import UIKit

/// Экран "Музыка", показывающий список треков с табами.
final class MusicCollectionViewController: UICollectionViewController {

    /// Секции коллекции.
    enum Section: Int, CaseIterable {
        case screenHeader
        case tabsHeader
        case tracks
    }
    
    /// Как показывается экран:
    /// - `tabRoot`  как корневой экран вкладки (скрыть навбар, отобразить хедер - собственный заголовок)
    /// - `pushed`   когда экран запушен из профиля/меню (используется системный нав бар)
    enum PresentationStyle {
        case tabRoot
        case pushed
    }

    weak var coordinator: MusicCoordinator?

    /// ViewModel экрана музыки (через протокол для тестируемости и подмены реализаций)
    private let viewModel: MusicViewModelProtocol

    /// Текущий стиль показа.
    private let presentationStyle: PresentationStyle

    /// Pull‑to‑refresh.
    private let refreshControl = UIRefreshControl()


    init(
        viewModel: MusicViewModelProtocol,
        presentationStyle: PresentationStyle = .tabRoot
    ) {
        self.viewModel = viewModel
        self.presentationStyle = presentationStyle

        // Конфигурация layout через compositional layout
        let layout = MusicCollectionViewController.makeLayout(
            presentationStyle: presentationStyle
        )
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        registerCellsAndHeaders()
        setupRefreshControl()
        bindViewModel()

        Task { [weak self] in
            await self?.viewModel.viewDidLoad()
        }
    }
   
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        switch presentationStyle {
        case .tabRoot:
            // В режиме вкладки таб бара спрятать навбар
            navigationController?.setNavigationBarHidden(true, animated: animated)

        case .pushed:
            // В pushed‑режиме наоборот показать
            navigationController?.setNavigationBarHidden(false, animated: animated)
            navigationItem.title = "Музыка"
            navigationItem.largeTitleDisplayMode = .never
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // При уходе с экрана вернуть нав бар
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setupView() {
        // Базовая настройка вида
        collectionView.backgroundColor = .appBackground
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true

        // Для pushed‑стиля использовать стандартный нав бар тайтл
        navigationController?.navigationItem.title = "Музыка"
    }

   
    private func bindViewModel() {
        // Сохранить предыдущие коллбэки, чтобы не затирать подписки других экранов
        let previousOnUpdate = viewModel.onUpdate
        viewModel.onUpdate = { [weak self] in
            // Сначала дергать тех, кто подписался раньше
            previousOnUpdate?()
            // Потом обновлять текущий экран
            self?.reloadAll()
        }

        let previousOnPlaybackUpdate = viewModel.onPlaybackUpdate
        
        // Локальное обновление только видимых треков при изменении воспроизведения
        viewModel.onPlaybackUpdate = { [weak self] in
            previousOnPlaybackUpdate?()
            self?.reloadVisibleTrackCells()
        }
    }

    /// Полный reload коллекции без анимаций.
    private func reloadAll() {
        UIView.performWithoutAnimation {
            self.collectionView.reloadData()
            self.collectionView.layoutIfNeeded()
        }
    }

    /// Обновляет только видимые ячейки с треками.
    private func reloadVisibleTrackCells() {
        let sectionIndex = Section.tracks.rawValue

        for indexPath in collectionView.indexPathsForVisibleItems
        where indexPath.section == sectionIndex {

            guard
                let cell = collectionView.cellForItem(at: indexPath) as? MusicTrackCell
            else {
                continue
            }

            let item = visibleTracks()[indexPath.item]
            let isPlaying = (item.id == viewModel.currentTrackId && viewModel.isPlaying)
            let isMyTab = (viewModel.selectedTab == .myTracks)
            let isInMy = viewModel.myTracks.contains { $0.id == item.id }

            cell.configure(
                with: item,
                isPlaying: isPlaying,
                isInMyTracks: isInMy,
                isMyTracksTab: isMyTab
            )
        }
    }

    /// Создаёт compositional layout в зависимости от стиля показа экрана.
    private static func makeLayout(
        presentationStyle: PresentationStyle
    ) -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { sectionIndex, environment in
            guard let section = Section(rawValue: sectionIndex) else { return nil }

            switch section {
            case .screenHeader:
                // В режиме pushed вообще не создавать эту секцию
                guard presentationStyle == .tabRoot else { return nil }

                // Секция из одного "невидимого" item, у которого только header
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(1)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: itemSize,
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
                section.contentInsets = .init(
                    top: 6,
                    leading: 16,
                    bottom: 0,
                    trailing: 0
                )
                return section

            case .tabsHeader:
                // Секция, в которой тоже только header, без ячеек
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
                    heightDimension: .estimated(44)
                )
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )

                section.boundarySupplementaryItems = [header]
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 0,
                    leading: 16,
                    bottom: 8,
                    trailing: 16
                )
                return section

            case .tracks:
                // Основной список треков — используется list‑appearance
                let config = UICollectionLayoutListConfiguration(appearance: .plain)
                return NSCollectionLayoutSection.list(
                    using: config,
                    layoutEnvironment: environment
                )
            }
        }
    }

    /// Регистрация ячеек и хедеров коллекции.
    private func registerCellsAndHeaders() {
        collectionView.register(
            MusicTrackCell.self,
            forCellWithReuseIdentifier: MusicTrackCell.reuseId
        )

        collectionView.register(
            MusicTabsHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MusicTabsHeaderView.reuseId
        )

        collectionView.register(
            TitleHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: TitleHeaderView.reuseId
        )
    }

    /// Настройка pull‑to‑refresh.
    private func setupRefreshControl() {
        refreshControl.addTarget(
            self,
            action: #selector(handleRefresh),
            for: .valueChanged
        )
        collectionView.refreshControl = refreshControl
    }

    /// Возвращает список треков, соответствующий текущему выбранному табу.
    private func visibleTracks() -> [MusicTrackItemViewData] {
        switch viewModel.selectedTab {
        case .main:
            return viewModel.mainTracks
        case .myTracks:
            return viewModel.myTracks
        }
    }

    /// Возвращает item трека по indexPath (только для секции .tracks).
    private func trackItem(at indexPath: IndexPath) -> MusicTrackItemViewData? {
        guard Section(rawValue: indexPath.section) == .tracks else { return nil }

        let items = visibleTracks()
        guard indexPath.item < items.count else { return nil }

        return items[indexPath.item]
    }

    /// Обработчик pull‑to‑refresh.
    @objc private func handleRefresh() {
        Task { [weak self] in
            guard let self else { return }
            await self.viewModel.refresh()

            // Имитация небольшой задержки, чтобы анимация не прерывалась мгновенно
            try? await Task.sleep(nanoseconds: 500_000_000)
            self.refreshControl.endRefreshing()
        }
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        Section.allCases.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }

        switch section {
        case .screenHeader, .tabsHeader:
            // Эти секции содержат только header, без ячеек
            return 0
        case .tracks:
            return visibleTracks().count
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
        case .tracks:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MusicTrackCell.reuseId,
                for: indexPath
            ) as! MusicTrackCell

            let item = visibleTracks()[indexPath.item]

            let isPlaying = (item.id == viewModel.currentTrackId && viewModel.isPlaying)
            let isMyTab = (viewModel.selectedTab == .myTracks)
            let isInMy = viewModel.myTracks.contains { $0.id == item.id }

            cell.configure(
                with: item,
                isPlaying: isPlaying,
                isInMyTracks: isInMy,
                isMyTracksTab: isMyTab
            )

            cell.onPlayPauseTapped = { [weak self] in
                guard let self else { return }
                Task {
                    await self.viewModel.didTapPlayPauseForTrack(id: item.id)
                }
            }

            cell.onSecondaryTapped = { [weak self] in
                self?.viewModel.toggleMyTrack(id: item.id)
            }

            return cell

        case .screenHeader, .tabsHeader:
            // Для этих секций не должно быть ячеек.
            return UICollectionViewCell()
        }
    }

    // MARK: - Supplementary views (headers)

    override func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let section = Section(rawValue: indexPath.section) else {
            return UICollectionReusableView()
        }

        switch section {
        case .screenHeader:
            // В pushed‑режиме не показывать заголовок
            guard presentationStyle == .tabRoot else {
                return UICollectionReusableView()
            }

            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: TitleHeaderView.reuseId,
                for: indexPath
            ) as! TitleHeaderView

            header.configurePrimary(title: "Музыка")
            return header
            
        case .tabsHeader:
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: MusicTabsHeaderView.reuseId,
                for: indexPath
            ) as! MusicTabsHeaderView

            header.configure(selectedTab: viewModel.selectedTab)

            // Переключение таба
            header.onTabChanged = { [weak self] tab in
                self?.viewModel.didSelectTab(tab)
            }

            return header

        case .tracks:
            // Для секции с треками header не используется
            return UICollectionReusableView()
        }
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard Section(rawValue: indexPath.section) == .tracks else { return }

        Task { [weak self] in
            await self?.viewModel.didSelectTrack(at: indexPath.item)
        }
    }
}
