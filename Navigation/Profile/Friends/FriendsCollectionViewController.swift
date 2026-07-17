import UIKit

//final class FriendsCollectionViewController: UICollectionViewController, FriendsViewModelOutput {
//    
//    weak var coordinator: ProfileCoordinator?
//    
//    private enum Section: Int, CaseIterable {
//        case tabsHeader = 0
//        case searchHeader = 1
//        case friends = 2
//    }
//    
//    private let viewModel: FriendsViewModel
//    private let refreshControl = UIRefreshControl()
//    
//    private var didFocusSearchOnce = false
//    private weak var searchHeaderView: SearchHeaderView?
//    
//    
//    init(viewModel: FriendsViewModel) {
//        self.viewModel = viewModel
//        
//        let layout = FriendsCollectionViewController.makeLayout()
//        super.init(collectionViewLayout: layout)
//        
//        commonInit()
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        title = NSLocalizedString("friends_title", comment: "Title of screen")
//        
//        collectionView.backgroundColor = .appBackground
//        
//        collectionView.alwaysBounceVertical = true
//        
//        // Ячейки
//        collectionView.register(
//            FriendCell.self,
//            forCellWithReuseIdentifier: FriendCell.reuseId
//        )
//        
//        // Хедер поиска
//        collectionView.register(
//            SearchHeaderView.self,
//            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
//            withReuseIdentifier: SearchHeaderView.reuseId
//        )
//        
//        collectionView.register(
//            SortCell.self,
//            forCellWithReuseIdentifier: SortCell.reuseId
//        )
//        
//        // Хедер с табами
//        collectionView.register(
//            FriendsTabsHeaderView.self,
//            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
//            withReuseIdentifier: FriendsTabsHeaderView.reuseId
//        )
//        
//        collectionView.refreshControl = refreshControl
//        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
//        
//        Task { await viewModel.viewDidLoad() }
//    }
//    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        navigationController?.setNavigationBarHidden(false, animated: animated)
//    }
//    
//    func didUpdateState(_ state: FriendsViewModel.State) {
//    
//        let friendsSection = Section.friends.rawValue
//        
//        // обновлить только секцию друзей
//        collectionView.performBatchUpdates {
//            let old = collectionView.numberOfItems(inSection: friendsSection)
//            let new = state.friends.count
//            
//            if new < old {
//                let indexes = (new..<old).map { IndexPath(item: $0, section: friendsSection) }
//                collectionView.deleteItems(at: indexes)
//            }
//            
//            if new > old {
//                let indexes = (old..<new).map { IndexPath(item: $0, section: friendsSection) }
//                collectionView.insertItems(at: indexes)
//            }
//            
//            let reloadCount = min(old, new)
//            let reloadIndexPaths = (0..<reloadCount).map { IndexPath(item: $0, section: friendsSection) }
//            collectionView.reloadItems(at: reloadIndexPaths)
//        }
//        
//        //  обновить уже видимый header с табами
//        if let header = collectionView.supplementaryView(
//            forElementKind: UICollectionView.elementKindSectionHeader,
//            at: IndexPath(item: 0, section: Section.tabsHeader.rawValue)
//        ) as? FriendsTabsHeaderView {
//            
//            let s = state
//            header.configure(
//                allCount: s.allFriendsCount,
//                onlineCount: s.onlineFriendsCount,
//                selectedIndex: s.selectedTab.rawValue
//            )
//        }
//        
//        let indexPath = IndexPath(item: 0, section: Section.searchHeader.rawValue)
//        if let cell = collectionView.cellForItem(at: indexPath) as? SortCell {
//            cell.configure(sortTitle: "\(state.selectedSort.rowTitle)")
//        }
//        
//        if !state.isLoading, refreshControl.isRefreshing {
//            refreshControl.endRefreshing()
//        }
//    }
//    
//    private func commonInit() {
//        viewModel.output = self
//    }
//    
//    private static func makeLayout() -> UICollectionViewLayout {
//        UICollectionViewCompositionalLayout { sectionIndex, _ in
//            guard let section = Section(rawValue: sectionIndex) else { return nil }
//            
//            switch section {
//            case .searchHeader:
//                // Секция: header с поиском + одна строка сортировки
//                let itemSize = NSCollectionLayoutSize(
//                    widthDimension: .fractionalWidth(1.0),
//                    heightDimension: .absolute(44)
//                )
//                let item = NSCollectionLayoutItem(layoutSize: itemSize)
//                
//                let groupSize = NSCollectionLayoutSize(
//                    widthDimension: .fractionalWidth(1.0),
//                    heightDimension: .absolute(44)
//                )
//                let group = NSCollectionLayoutGroup.vertical(
//                    layoutSize: groupSize,
//                    subitems: [item]
//                )
//                
//                let section = NSCollectionLayoutSection(group: group)
//                
//                let headerSize = NSCollectionLayoutSize(
//                    widthDimension: .fractionalWidth(1.0),
//                    heightDimension: .estimated(56)
//                )
//                let header = NSCollectionLayoutBoundarySupplementaryItem(
//                    layoutSize: headerSize,
//                    elementKind: UICollectionView.elementKindSectionHeader,
//                    alignment: .top
//                )
//                section.boundarySupplementaryItems = [header]
//                return section
//                
//            case .tabsHeader:
//                // Пустая секция, только header с табами
//                let itemSize = NSCollectionLayoutSize(
//                    widthDimension: .fractionalWidth(1.0),
//                    heightDimension: .absolute(1)
//                )
//                let item = NSCollectionLayoutItem(layoutSize: itemSize)
//                let groupSize = NSCollectionLayoutSize(
//                    widthDimension: .fractionalWidth(1.0),
//                    heightDimension: .absolute(1)
//                )
//                let group = NSCollectionLayoutGroup.horizontal(
//                    layoutSize: groupSize,
//                    subitems: [item]
//                )
//                let section = NSCollectionLayoutSection(group: group)
//                
//                let headerSize = NSCollectionLayoutSize(
//                    widthDimension: .fractionalWidth(1.0),
//                    heightDimension: .estimated(44)
//                )
//                let header = NSCollectionLayoutBoundarySupplementaryItem(
//                    layoutSize: headerSize,
//                    elementKind: UICollectionView.elementKindSectionHeader,
//                    alignment: .top
//                )
//                section.boundarySupplementaryItems = [header]
//                return section
//                
//            case .friends:
//                // Список друзей
//                let itemSize = NSCollectionLayoutSize(
//                    widthDimension: .fractionalWidth(1.0),
//                    heightDimension: .estimated(65)
//                )
//                let item = NSCollectionLayoutItem(layoutSize: itemSize)
//                let groupSize = NSCollectionLayoutSize(
//                    widthDimension: .fractionalWidth(1.0),
//                    heightDimension: .estimated(65)
//                )
//                let group = NSCollectionLayoutGroup.vertical(
//                    layoutSize: groupSize,
//                    subitems: [item]
//                )
//                let section = NSCollectionLayoutSection(group: group)
//                section.contentInsets = NSDirectionalEdgeInsets(
//                    top: 8,
//                    leading: 16,
//                    bottom: 8,
//                    trailing: 16
//                )
//                section.interGroupSpacing = 8
//                return section
//            }
//        }
//    }
//    
//    private func presentSortSheet(current: FriendsViewModel.Sort) {
//        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//        
//        FriendsViewModel.Sort.allCases.forEach { sort in
//            let action = UIAlertAction(title: sort.title, style: .default) { [weak self] _ in
//                self?.viewModel.didSelectSort(sort)
//            }
//            
//            if sort == current {
//                action.setValue(UIImage(systemName: "checkmark"), forKey: "image")
//            }
//            
//            alert.addAction(action)
//        }
//        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
//        present(alert, animated: true)
//    }
//    
//    @objc private func didPullToRefresh() {
//        Task { [weak self] in
//            await self?.viewModel.load()
//        }
//    }
//}
//
//extension FriendsCollectionViewController {
//
//    override func numberOfSections(in collectionView: UICollectionView) -> Int {
//        Section.allCases.count
//    }
//
//    override func collectionView(_ collectionView: UICollectionView,
//                                 numberOfItemsInSection section: Int) -> Int {
//        guard let section = Section(rawValue: section) else { return 0 }
//
//        switch section {
//        case .searchHeader:
//            return 1      // строка сортировки
//        case .tabsHeader:
//            return 0      // только header
//        case .friends:
//            return viewModel.state.friends.count
//        }
//    }
//
//    override func collectionView(_ collectionView: UICollectionView,
//                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        guard let section = Section(rawValue: indexPath.section) else {
//            return UICollectionViewCell()
//        }
//
//        switch section {
//        case .friends:
//            let cell = collectionView.dequeueReusableCell(
//                withReuseIdentifier: FriendCell.reuseId,
//                for: indexPath
//            ) as! FriendCell
//
//            let item = viewModel.state.friends[indexPath.item]
//            let subtitle = viewModel.subtitleText(for: item)
//
//            cell.configure(
//                name: item.displayName,
//                avatarPath: item.avatarPath,
//                subtitleText: subtitle,
//                isOnline: item.isOnline
//            )
//            return cell
//
//        case .searchHeader:
//            let cell = collectionView.dequeueReusableCell(
//                withReuseIdentifier: SortCell.reuseId,
//                for: indexPath
//            ) as! SortCell
//
//            cell.configure(sortTitle: viewModel.state.selectedSort.rowTitle)
//
//            cell.onTap = { [weak self] in
//                guard let self else { return }
//                self.presentSortSheet(current: self.viewModel.state.selectedSort)
//            }
//
//            return cell
//
//        case .tabsHeader:
//            return UICollectionViewCell()
//        }
//    }
//
//    // MARK: Headers
//
//    override func collectionView(_ collectionView: UICollectionView,
//                                 viewForSupplementaryElementOfKind kind: String,
//                                 at indexPath: IndexPath) -> UICollectionReusableView {
//
//        guard kind == UICollectionView.elementKindSectionHeader,
//              let section = Section(rawValue: indexPath.section) else {
//            return UICollectionReusableView()
//        }
//
//        switch section {
//        case .searchHeader:
//            let header = collectionView.dequeueReusableSupplementaryView(
//                ofKind: kind,
//                withReuseIdentifier: SearchHeaderView.reuseId,
//                for: indexPath
//            ) as! SearchHeaderView
//
//            header.onSearchTextChanged = { [weak self] text in
//                self?.viewModel.didChangeSearchText(text)
//            }
//            return header
//
//        case .tabsHeader:
//            let header = collectionView.dequeueReusableSupplementaryView(
//                ofKind: kind,
//                withReuseIdentifier: FriendsTabsHeaderView.reuseId,
//                for: indexPath
//            ) as! FriendsTabsHeaderView
//
//            let s = viewModel.state
//            header.configure(
//                allCount: s.allFriendsCount,
//                onlineCount: s.onlineFriendsCount,
//                selectedIndex: s.selectedTab.rawValue
//            )
//            header.onTabChanged = { [weak self] index in
//                self?.viewModel.didSelectTab(index: index)
//            }
//            return header
//
//        case .friends:
//            return UICollectionReusableView()
//        }
//    }
//
//    override func collectionView(_ collectionView: UICollectionView,
//                                 didSelectItemAt indexPath: IndexPath) {
//        guard let section = Section(rawValue: indexPath.section) else { return }
//
//        switch section {
//        case .friends:
//            let friend = viewModel.state.friends[indexPath.item]
//            // если нужно — пробрасываешь дальше через координатор
//            // coordinator?.showFriendProfile(id: friend.id)
//            print("Tap friend: \(friend.displayName)")
//
//        case .searchHeader, .tabsHeader:
//            break
//        }
//    }
//}
//

/// Экран списка друзей.
///
/// Показывает:
/// 1. хедер с табами (все / онлайн)
/// 2.  хедер с поиском
/// 3.  список друзей
final class FriendsCollectionViewController: UICollectionViewController, FriendsViewModelOutput {
    
    /// Секции коллекции
    private enum Section: Int, CaseIterable {
        case tabsHeader = 0
        case searchHeader = 1
        case friends = 2
    }
    
    weak var coordinator: ProfileCoordinator?
    private let viewModel: FriendsViewModel
    
    private let refreshControl = UIRefreshControl()
    
    private var didFocusSearchOnce = false
    
    private weak var searchHeaderView: SearchHeaderView?
    
    init(viewModel: FriendsViewModel) {
        self.viewModel = viewModel
        
        let layout = FriendsCollectionViewController.makeLayout()
        super.init(collectionViewLayout: layout)
        
        viewModel.output = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("friends_title", comment: "Title of screen")
        
        setupCollectionView()
        setupRefreshControl()
        
        Task { await viewModel.viewDidLoad() }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    /// Вызывается при каждом изменении состояния во ViewModel.
    func didUpdateState(_ state: FriendsViewModelState) {
        updateFriendsSection(with: state)
        updateTabsHeader(with: state)
        updateSortCell(with: state)
        updateLoadingState(with: state)
    }
    
    /// Регистрация ячеек и хедеров, базовая настройка коллекции.
    private func setupCollectionView() {
        collectionView.backgroundColor = .appBackground
        collectionView.alwaysBounceVertical = true
        
        // Ячейка друга
        collectionView.register(
            FriendCell.self,
            forCellWithReuseIdentifier: FriendCell.reuseId
        )
        
        // Ячейка сортировки
        collectionView.register(
            SortCell.self,
            forCellWithReuseIdentifier: SortCell.reuseId
        )
        
        // Хедер поиска
        collectionView.register(
            SearchHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SearchHeaderView.reuseId
        )
        
        // Хедер с табами
        collectionView.register(
            FriendsTabsHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: FriendsTabsHeaderView.reuseId
        )
    }
    
    /// Настройка pull‑to‑refresh.
    private func setupRefreshControl() {
        collectionView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
    }
    
    /// Анимированно обновляет только секцию друзей (добавление/удаление/перезагрузка).
    private func updateFriendsSection(with state: FriendsViewModelState) {
        let friendsSection = Section.friends.rawValue
        
        collectionView.performBatchUpdates {
            let oldCount = collectionView.numberOfItems(inSection: friendsSection)
            let newCount = state.friends.count
            
            // Удалить лишние элементы
            if newCount < oldCount {
                let indexes = (newCount..<oldCount).map {
                    IndexPath(item: $0, section: friendsSection)
                }
                collectionView.deleteItems(at: indexes)
            }
            
            // Вставить новые элементы
            if newCount > oldCount {
                let indexes = (oldCount..<newCount).map {
                    IndexPath(item: $0, section: friendsSection)
                }
                collectionView.insertItems(at: indexes)
            }
            
            // Перезагрузить те, что остались на тех же позициях
            let reloadCount = min(oldCount, newCount)
            let reloadIndexPaths = (0..<reloadCount).map {
                IndexPath(item: $0, section: friendsSection)
            }
            collectionView.reloadItems(at: reloadIndexPaths)
        }
    }
    
    /// Обновляет уже видимый header с табами (если он есть на экране).
    private func updateTabsHeader(with state: FriendsViewModelState) {
        guard let header = collectionView.supplementaryView(
            forElementKind: UICollectionView.elementKindSectionHeader,
            at: IndexPath(item: 0, section: Section.tabsHeader.rawValue)
        ) as? FriendsTabsHeaderView else {
            return
        }
        
        header.configure(
            allCount: state.allFriendsCount,
            onlineCount: state.onlineFriendsCount,
            selectedIndex: state.selectedTab.rawValue
        )
    }
    
    /// Обновляет строку сортировки (ячейку SortCell)
    private func updateSortCell(with state: FriendsViewModelState) {
        let indexPath = IndexPath(item: 0, section: Section.searchHeader.rawValue)
        guard let cell = collectionView.cellForItem(at: indexPath) as? SortCell else {
            return
        }
        cell.configure(sortTitle: state.selectedSort.rowTitle)
    }
    
    /// Управляет индикацией pull‑to‑refresh.
    private func updateLoadingState(with state: FriendsViewModelState) {
        if !state.isLoading, refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
    }
    
    /// Создание компоновки для всех секций.
    private static func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in
            guard let section = Section(rawValue: sectionIndex) else { return nil }
            
            switch section {
            case .searchHeader:
                return makeSearchHeaderSection()
            case .tabsHeader:
                return makeTabsHeaderSection()
            case .friends:
                return makeFriendsSection()
            }
        }
    }
    
    /// Секция: header с поиском + одна строка сортировки.
    private static func makeSearchHeaderSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(44)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(44)
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            subitems: [item]
        )
        
        let section = NSCollectionLayoutSection(group: group)
        
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(56)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]
        return section
    }
    
    /// Пустая секция, только header с табами.
    private static func makeTabsHeaderSection() -> NSCollectionLayoutSection {
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
        return section
    }
    
    /// Секция: список друзей.
    private static func makeFriendsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(65)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(65)
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            subitems: [item]
        )
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 8,
            leading: 16,
            bottom: 8,
            trailing: 16
        )
        section.interGroupSpacing = 8
        return section
    }
    
    /// Обработка pull‑to‑refresh.
    @objc private func didPullToRefresh() {
        Task { [weak self] in
            await self?.viewModel.load()
        }
    }
    
    /// Показывает системный Action Sheet с вариантами сортировки.
    private func presentSortSheet(current: FriendsViewModel.Sort) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        FriendsViewModel.Sort.allCases.forEach { sort in
            let action = UIAlertAction(title: sort.title, style: .default) { [weak self] _ in
                self?.viewModel.didSelectSort(sort)
            }
            
            // Для текущего варианта сортировки - чекбокс
            if sort == current {
                action.setValue(UIImage(systemName: "checkmark"), forKey: "image")
            }
            
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource & Delegate

extension FriendsCollectionViewController {
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        Section.allCases.count
    }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        
        switch section {
        case .searchHeader:
            return 1      // одна ячейка сортировки под хедером поиска
        case .tabsHeader:
            return 0      // только header, без ячеек
        case .friends:
            return viewModel.state.friends.count
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
        case .friends:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: FriendCell.reuseId,
                for: indexPath
            ) as! FriendCell
            
            let item = viewModel.state.friends[indexPath.item]
            let subtitle = viewModel.subtitleText(for: item)
            
            cell.configure(
                name: item.displayName,
                avatarPath: item.avatarPath,
                subtitleText: subtitle,
                isOnline: item.isOnline
            )
            
            return cell
            
        case .searchHeader:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: SortCell.reuseId,
                for: indexPath
            ) as! SortCell
            
            cell.configure(sortTitle: viewModel.state.selectedSort.rowTitle)
            
            cell.onTap = { [weak self] in
                guard let self else { return }
                self.presentSortSheet(current: self.viewModel.state.selectedSort)
            }
            
            return cell
            
        case .tabsHeader:
            return UICollectionViewCell()
        }
    }
    
    // MARK: Headers
    
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
        case .searchHeader:
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: SearchHeaderView.reuseId,
                for: indexPath
            ) as! SearchHeaderView
            
            // Проброс изменения текста поиска во ViewModel
            header.onSearchTextChanged = { [weak self] text in
                self?.viewModel.didChangeSearchText(text)
            }
            searchHeaderView = header
            
            return header
            
        case .tabsHeader:
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: FriendsTabsHeaderView.reuseId,
                for: indexPath
            ) as! FriendsTabsHeaderView
            
            let s = viewModel.state
            header.configure(
                allCount: s.allFriendsCount,
                onlineCount: s.onlineFriendsCount,
                selectedIndex: s.selectedTab.rawValue
            )
            
            // Реакция на смену таба
            header.onTabChanged = { [weak self] index in
                self?.viewModel.didSelectTab(index: index)
            }
            
            return header
            
        case .friends:
            return UICollectionReusableView()
        }
    }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard let section = Section(rawValue: indexPath.section) else { return }
        
        switch section {
        case .friends:
            let friend = viewModel.state.friends[indexPath.item]
            
            AppLogger.debug("Tap friend: \(friend.displayName)")
            
        case .searchHeader, .tabsHeader:
            break
        }
    }
}
