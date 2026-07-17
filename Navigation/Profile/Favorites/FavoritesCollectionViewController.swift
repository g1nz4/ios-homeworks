import UIKit

/// Экран списка избранного.
/// Показывает (пока только) посты в коллекции, позволяет искать по автору, убирать из избранного и разворачивать длинный текст.
final class FavoritesCollectionViewController: UICollectionViewController {
    
    private enum Section: Int, CaseIterable {
        case header = 0
        case posts = 1
    }
    
    weak var coordinator: ProfileCoordinator?
    
    private let user: User
    private let viewModel: FavoritesViewModel
    
    init(user: User, viewModel: FavoritesViewModel) {
        self.user = user
        self.viewModel = viewModel
        
        let layout = FavoritesCollectionViewController.createLayout()
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        setupCollectionView()
        bindViewModel()
        
        Task { await viewModel.loadFavorites() }
    }
    
    /// Конфигурирует навбар.
    private func setupNavigationBar() {
        title = "Избранное"
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    private static func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, environment in
            guard let section = Section(rawValue: sectionIndex) else { return nil }
            
            switch section {
            case .header:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(1)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(1)
                )
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: groupSize,
                    subitems: [item]
                )
                
                let sectionLayout = NSCollectionLayoutSection(group: group)
                
                // Хедер
                let headerSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(52)
                )
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                sectionLayout.boundarySupplementaryItems = [header]
                
                return sectionLayout
                
            case .posts:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(320)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(320)
                )
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: groupSize,
                    subitems: [item]
                )
                
                let sectionLayout = NSCollectionLayoutSection(group: group)
                sectionLayout.interGroupSpacing = 8
                sectionLayout.contentInsets = NSDirectionalEdgeInsets(
                    top: 8, leading: 0, bottom: 8, trailing: 0
                )
                return sectionLayout
            }
        }
    }
    
    /// Регистрирует ячейки и задаёт фон коллекции.
    private func setupCollectionView() {
        collectionView.register(
            PostCollectionViewCell.self,
            forCellWithReuseIdentifier: PostCollectionViewCell.reuseId
        )
        collectionView.register(
            SearchHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SearchHeaderView.reuseId
        )
        collectionView.backgroundColor = .appBackground
    }
    
    /// Подписка на изменения во ViewModel.
    private func bindViewModel() {
        viewModel.onPostsChanged = { [weak self] _ in
            guard let self else { return }
            self.collectionView.reloadData()
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
        guard let sectionKind = Section(rawValue: section) else { return 0 }
        
        switch sectionKind {
        case .header:
            return 0
        case .posts:
            return viewModel.posts.count
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
            
        case .posts:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PostCollectionViewCell.reuseId,
                for: indexPath
            ) as! PostCollectionViewCell
            
            let basePost = viewModel.posts[indexPath.item]
            var post = basePost
            post.isExpanded = viewModel.isExpanded(postId: basePost.id)
            
            cell.configure(with: post, user: user)
            cell.delegate = self
            
            cell.configureMenu(
                isFavorite: true,
                favoriteTitle: "Удалить из избранного",
                favoriteAlwaysYellow: true,
                onFavorite: { [weak self, weak cell] in
                    guard
                        let self,
                        let cell,
                        let currentIndexPath = self.collectionView.indexPath(for: cell)
                    else { return }
                    
                    Task { @MainActor in
                        if (await self.viewModel.removeFromFavorites(at: currentIndexPath.item)) != nil {
                            UIView.performWithoutAnimation {
                                self.collectionView.deleteItems(at: [currentIndexPath])
                                self.collectionView.layoutIfNeeded()
                            }
                        }
                    }
                },
                onEdit: nil,
                onDelete: nil
            )
            
            return cell
        }
    }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }

        guard let section = Section(rawValue: indexPath.section) else {
            return UICollectionReusableView()
        }

        switch section {
        case .header:
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: SearchHeaderView.reuseId,
                for: indexPath
            ) as! SearchHeaderView

            header.onSearchTextChanged = { [weak self] text in
                guard let self else { return }

                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                let filter = trimmed.isEmpty ? nil : trimmed

                Task { await self.viewModel.setFilter(author: filter) }

                if !(filter?.isEmpty ?? true), self.viewModel.posts.isEmpty {
                    AppLogger.error("Автор \"\(trimmed)\" не найден.")
                }
            }

            return header

        case .posts:
            return UICollectionReusableView()
        }
    }
}

// MARK: - PostCollectionViewCellDelegate

extension FavoritesCollectionViewController: PostCollectionViewCellDelegate {
   
    /// Тап по лайку в ячейке.
    func postCellDidTapLike(_ cell: PostCollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }

        Task { @MainActor in
            if let updated = await viewModel.toggleLike(at: indexPath.item) {
                // Локально обновить UI ячейки
                cell.updateLikeState(isLiked: updated.isLiked, likes: updated.likes)
            }
        }
    }

    /// Тап по "Показать ещё" / "Скрыть".
    func postCellDidTapMore(_ cell: PostCollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        
        let post = viewModel.posts[indexPath.item]
        viewModel.toggleExpanded(postId: post.id)
        
        // Пересоздать ячейку с новым состоянием без анимации, чтобы не было скачка высоты
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
    
    func postCellDidTapImage(_ cell: PostCollectionViewCell) {
        guard
            let indexPath = collectionView.indexPath(for: cell),
            let coordinator
        else {
            return
        }
        
        let post = viewModel.posts[indexPath.item]
      
       
        guard
            let path = post.imagePath,
            !path.isEmpty,
            let url = URL(string: path)
        else {
            AppLogger.debug("[PROFILE] postCellDidTapImage: no valid image url for post \(post.id)")
            return
        }

        let photo = Photo(id: post.id, url: url, albumId: nil)
        
        coordinator.showPhotoViewer(
            photos: [photo],
            startIndex: 0,
            delegate: coordinator,
            showAddToSaved: true,
            viewInPost: true
        )
    }
    
    func postCellDidTapShare(_ cell: PostCollectionViewCell) { }
}
