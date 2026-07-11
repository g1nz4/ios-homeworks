import UIKit
import StorageService

/// Делегат для синхронизации изменений избранных постов.
protocol FavoritesDelegate: AnyObject {
    /// Пост с таким id был удалён из избранного
    func favoritesDidRemoveFromFavorites(postId: String)
    /// В избранном обновился пост (лайк)
    func favoritesDidUpdate(post: MyPost)
}

/// Экран списка избранного.
/// Показывает посты в коллекции, позволяет искать по автору, убирать из избранного и разворачивать длинный текст.
final class FavoritesCollectionViewController: UICollectionViewController {

    weak var coordinator: ProfileCoordinator?
    weak var favoritesDelegate: FavoritesDelegate?

    private let user: User
    private let viewModel: FavoritesViewModel

    /// Поисковая строка для фильтрации.
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.searchBarStyle = .minimal
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        searchBar.delegate = self
        
        return searchBar
    }()

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
        configureSearchBarAppearance()
        setupCollectionView()
        bindViewModel()

        // Первичная загрузка избранного
        Task { await viewModel.loadFavorites() }
    }

    /// Конфигурирует навбар и встраивает searchBar в titleView.
    private func setupNavigationBar() {
        title = "Избранное"
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.titleView = searchBar
    }
    
    private static func createLayout() -> UICollectionViewLayout {
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

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 8, leading: 0, bottom: 8, trailing: 0
        )

        return UICollectionViewCompositionalLayout(section: section)
    }

    /// Регистрирует ячейки и задаёт фон коллекции.
    private func setupCollectionView() {
        collectionView.register(
            PostCollectionViewCell.self,
            forCellWithReuseIdentifier: PostCollectionViewCell.reuseId
        )
        collectionView.backgroundColor = .appBackground
    }

    /// Кастомизация внешнего вида `UISearchBar`.
    private func configureSearchBarAppearance() {
        let textField = searchBar.searchTextField

        textField.backgroundColor = .appTextFieldBackground
        textField.textColor = .appSecondaryText
        textField.tintColor = .appAccent
        textField.attributedPlaceholder = NSAttributedString(
            string: "Поиск по автору",
            attributes: [.foregroundColor: UIColor.appSecondaryText]
        )

        if let leftIconView = textField.leftView as? UIImageView {
            leftIconView.tintColor = .appSecondaryText
        }
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
        1
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        viewModel.posts.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PostCollectionViewCell.reuseId,
            for: indexPath
        ) as! PostCollectionViewCell

        let basePost = viewModel.posts[indexPath.item]
        var post = basePost
        post.isExpanded = viewModel.isExpanded(postId: basePost.id)

        cell.configure(with: post, user: user)
        cell.delegate = self

        // Меню ячейки в избранном: только "Удалить из избранного".
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
                    if let postId = await self.viewModel.removeFromFavorites(at: currentIndexPath.item) {
                        // Удалить ячейку без анимации, чтобы избежать скачков layout
                        UIView.performWithoutAnimation {
                            self.collectionView.deleteItems(at: [currentIndexPath])
                            self.collectionView.layoutIfNeeded()
                        }
                        self.favoritesDelegate?.favoritesDidRemoveFromFavorites(postId: postId)
                    }
                }
            },
            onEdit: nil,
            onDelete: nil
        )

        return cell
    }
}

// MARK: - UISearchBarDelegate

extension FavoritesCollectionViewController: UISearchBarDelegate {

    /// Реагирует на изменение текста в поиске: фильтр по имени автора.
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filter = text.isEmpty ? nil : text

        Task { await viewModel.setFilter(author: filter) }

        if !(filter?.isEmpty ?? true), viewModel.posts.isEmpty {
            AppLogger.error("Автор \"\(text)\" не найден.")
        }
    }

    /// Скрыть клавиатуру по нажатию кнопки "Поиск".
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
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
                // Сообщить делегату, чтобы синхронизировать другие экраны
                favoritesDelegate?.favoritesDidUpdate(post: updated)
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
            collectionView.reloadItems(at: [indexPath])
            collectionView.layoutIfNeeded()
        }
    }
}
