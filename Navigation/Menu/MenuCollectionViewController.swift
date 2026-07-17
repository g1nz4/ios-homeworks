import UIKit

/// Экран меню с коллекцией:
/// 1. Секция профиля (одна ячейка)
/// 2. Секция пунктов меню (сеткой)
final class MenuCollectionViewController: UICollectionViewController {
    
    /// Секции коллекции
    private enum Section: Int, CaseIterable {
        case profile
        case menu
    }
    
    weak var coordinator: MenuCoordinator?

    private let viewModel: MenuViewModel

    /// Коллбек выбора элемента меню
    var onItemSelected: ((MenuItem) -> Void)?

    /// Коллбек нажатия на Edit в профиле
    var onEditProfileTap: (() -> Void)?

    /// Коллбек изменения пользователя
    var onUserChanged: ((User) -> Void)?

    init(viewModel: MenuViewModel) {
        self.viewModel = viewModel
        
        let layout = MenuCollectionViewController.makeLayout()
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appSecondaryBackground

        configureCollectionView()
        bindViewModel()
        
        viewModel.onItemsUpdated = { [weak self] in
            self?.collectionView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
       
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func bindViewModel() {
        viewModel.onUserChanged = { [weak self] user in
            guard let self else { return }

            // Перезагрузка только секции профиля
            let indexSet = IndexSet(integer: Section.profile.rawValue)
            self.collectionView.reloadSections(indexSet)

            // Прокидывание изменений пользователя наружу
            self.onUserChanged?(user)
        }
    }
    
    /// Внешний метод для обновления заголовка/профиля
    func updateHeader(with user: User) {
        viewModel.updateUser(user)
    }
    
    private func configureCollectionView() {
        collectionView.backgroundColor = .appBackground

        // Header с заголовком "Меню" и кнопкой "инфо"
        collectionView.register(
            MenuHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MenuHeaderView.reuseId
        )

        // Заголовок с тайтлом
        collectionView.register(
            TitleHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: TitleHeaderView.reuseId
        )

        // Ячейки
        collectionView.register(
            MenuItemCell.self,
            forCellWithReuseIdentifier: MenuItemCell.reuseId
        )
        collectionView.register(
            ProfileCell.self,
            forCellWithReuseIdentifier: ProfileCell.reuseId
        )
    }
    
    /// Конфигурация компоновки коллекции
    static func makeLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, _ in
            guard let section = Section(rawValue: sectionIndex) else { return nil }
            
            let baseInset: CGFloat = 16
            let headerToContent: CGFloat = 16
            let sectionBottom: CGFloat = 8
            
            switch section {

            case .profile:
                // Одна ячейка на всю ширину, высота по контенту
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(70)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: itemSize,
                    subitems: [item]
                )
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: headerToContent,
                    leading: baseInset,
                    bottom: sectionBottom,
                    trailing: baseInset
                )
                
                // Хедер с заголовком "Меню"
                let headerSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(32)
                )
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                header.contentInsets = NSDirectionalEdgeInsets(
                    top: 0,
                    leading: baseInset,
                    bottom: 0,
                    trailing: baseInset
                )
                section.boundarySupplementaryItems = [header]
                return section
                
            case .menu:
                // Сетка 4 элемента в ряд
                let interItemSpacing: CGFloat = 10
                
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0 / 4.0),
                    heightDimension: .absolute(100)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: itemSize.heightDimension
                )
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitem: item,
                    count: 4
                )
                group.interItemSpacing = .fixed(interItemSpacing)
                
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 10
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 8,
                    leading: baseInset,
                    bottom: sectionBottom,
                    trailing: baseInset
                )
                return section
            }
        }
        return layout
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
        case .profile:
            return 1
        case .menu:
            return viewModel.numberOfItems
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
        case .profile:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ProfileCell.reuseId,
                for: indexPath
            ) as! ProfileCell

            cell.configure(
                userDisplayName: viewModel.userName,
                userAvatarURL: viewModel.avatarURLString
            )

            // Обработка нажатия на кнопку редактирования профиля
            cell.onEditTap = { [weak self] in
                self?.onEditProfileTap?()
            }
            return cell
            
        case .menu:
            guard
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: MenuItemCell.reuseId,
                    for: indexPath
                ) as? MenuItemCell,
                let item = viewModel.item(at: indexPath.item)
            else {
                return UICollectionViewCell()
            }
            cell.configure(with: item)
            return cell
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
        case .profile:
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: MenuHeaderView.reuseId,
                for: indexPath
            ) as! MenuHeaderView

            header.configure(title: "Меню")
            header.onInfoTap = { [weak self] in
                self?.coordinator?.present(.info)
            }
            return header

        case .menu:
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
        case .menu:
            guard let item = viewModel.item(at: indexPath.item) else { return }
            onItemSelected?(item)

        case .profile:
            // Тап по ячейке профиля сейчас не обрабатывается
            break
        }
    }
}
