import UIKit

/// Делегат полноэкранного просмотрщика фото.
protocol PhotosViewerViewControllerDelegate: AnyObject {
    func photoViewer(_ vc: PhotoViewerViewController, didChooseAvatarFrom photo: Photo)
    func photoViewer(_ vc: PhotoViewerViewController, didChooseCoverFrom photo: Photo)
    func photoViewer(_ vc: PhotoViewerViewController, didAddToSaved photo: Photo)
    func photoViewer(_ vc: PhotoViewerViewController, didDelete photo: Photo)
}

/// Полноэкранный просмотр фото с горизонтальным скроллом и меню действий.
final class PhotoViewerViewController: UICollectionViewController {

    weak var delegate: PhotosViewerViewControllerDelegate?

    var onSetAsAvatar: ((Photo) -> Void)?
    var onSetAsCover: ((Photo) -> Void)?
    var onAddToSaved: ((Photo) -> Void)?

    private var previousStandardAppearance: UINavigationBarAppearance?
    private var previousScrollEdgeAppearance: UINavigationBarAppearance?
    private var previousTintColor: UIColor?

    private var backButtonItem: UIBarButtonItem!
    private var moreButtonItem: UIBarButtonItem!
    
    private let photos: [Photo]
    private let startIndex: Int
    private var currentIndex: Int
    private var didScrollToStartIndex = false
    private let showAddToSaved: Bool

   

    init(photos: [Photo], startIndex: Int, showAddToSaved: Bool = true) {
        self.photos = photos

        // Страховка от выхода за границы
        let safeIndex = max(0, min(startIndex, photos.count - 1))
        self.startIndex = safeIndex
        self.currentIndex = safeIndex
        self.showAddToSaved = showAddToSaved

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0

        super.init(collectionViewLayout: layout)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupCollectionView()
        setupNavigationBar()
        updateTitle()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutCollectionItemsIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyDarkTransparentNavBar()
        hideTabBarIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        restoreNavBarAppearance()
        showTabBarIfNeeded()
    }

    
    private func setupCollectionView() {
        collectionView.backgroundColor = .black
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false

        collectionView.register(
            PhotoViewerCell.self,
            forCellWithReuseIdentifier: PhotoViewerCell.reuseId
        )
    }

    private func setupNavigationBar() {
        backButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(didTapBack)
        )
        moreButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain,
            target: nil,
            action: nil
        )
        moreButtonItem.menu = makePhotoMenu()
        moreButtonItem.primaryAction = nil
        
        navigationItem.leftBarButtonItem = backButtonItem
        navigationItem.rightBarButtonItem = moreButtonItem
    }

    /// Подгоняет размер items под текущие bounds и скроллит к стартовому индексу один раз.
    private func layoutCollectionItemsIfNeeded() {
        guard !photos.isEmpty else { return }

        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = collectionView.bounds.size
        }

        if !didScrollToStartIndex {
            didScrollToStartIndex = true
            let pageWidth = collectionView.bounds.width
            let x = CGFloat(startIndex) * pageWidth
            collectionView.setContentOffset(CGPoint(x: x, y: 0), animated: false)
        }
    }

    /// Настройки навбара..
    private func applyDarkTransparentNavBar() {
        guard let navBar = navigationController?.navigationBar else { return }

        previousStandardAppearance = navBar.standardAppearance
        previousScrollEdgeAppearance = navBar.scrollEdgeAppearance
        previousTintColor = navBar.tintColor

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.tintColor = .white

        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    /// Восстанавливает навбар в состояние до открытия просмотра фото.
    private func restoreNavBarAppearance() {
        guard let navBar = navigationController?.navigationBar else { return }

        if let prevStd = previousStandardAppearance {
            navBar.standardAppearance = prevStd
        }
        if let prevScroll = previousScrollEdgeAppearance {
            navBar.scrollEdgeAppearance = prevScroll
        }
        if let tint = previousTintColor {
            navBar.tintColor = tint
        }
    }
    
    /// Скрыть таббар.
    private func hideTabBarIfNeeded() {
        rootTabContainerController?.setTabBarHidden(true, animated: true)
    }
    
    /// Показать таббар.
    private func showTabBarIfNeeded() {
        rootTabContainerController?.setTabBarHidden(false, animated: true)
    }

    /// Строит меню действий для текущего фото.
    private func makePhotoMenu() -> UIMenu {
        guard photos.indices.contains(currentIndex) else {
            return UIMenu(title: "", children: [])
        }

        let photo = photos[currentIndex]

        let avatarAction = UIAction(
            title: "Сделать фотографией профиля",
            image: UIImage(systemName: "person.crop.circle")
        ) { [weak self] _ in
            guard let self else { return }
            delegate?.photoViewer(self, didChooseAvatarFrom: photo)
            onSetAsAvatar?(photo)
        }

        let coverAction = UIAction(
            title: "Сделать обложкой профиля",
            image: UIImage(systemName: "photo")
        ) { [weak self] _ in
            guard let self else { return }
            delegate?.photoViewer(self, didChooseCoverFrom: photo)
            onSetAsCover?(photo)
        }

        var actions: [UIAction] = [avatarAction, coverAction]

        if showAddToSaved {
            let savedAction = UIAction(
                title: "Добавить в сохранённые",
                image: UIImage(systemName: "photo.badge.plus")
            ) { [weak self] _ in
                guard let self else { return }
                delegate?.photoViewer(self, didAddToSaved: photo)
                onAddToSaved?(photo)
            }
            actions.append(savedAction)
        }

        let deleteAction = UIAction(
            title: "Удалить фото",
            image: UIImage(systemName: "trash"),
            attributes: .destructive
        ) { [weak self] _ in
            guard let self else { return }
            delegate?.photoViewer(self, didDelete: photo)
        }

        actions.append(deleteAction)

        return UIMenu(title: "", children: actions)
    }

    /// Текущий индекс фото из всех в массиве ( `N из N` в навигационном баре).
    private func updateTitle() {
        guard !photos.isEmpty else {
            title = nil
            return
        }
        title = "\(currentIndex + 1) из \(photos.count)"
    }

    /// Пересчитывает текущий индекс страницы по offset’у, обновляет заголовок и меню.
    private func updateCurrentIndexIfNeeded() {
        let pageWidth = collectionView.bounds.width
        guard pageWidth > 0 else { return }

        let page = Int(round(collectionView.contentOffset.x / pageWidth))
        let clamped = max(0, min(page, photos.count - 1))
        currentIndex = clamped
        updateTitle()

        navigationItem.rightBarButtonItem?.menu = makePhotoMenu()
    }


    @objc private func didTapBack() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Scroll callbacks

    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentIndexIfNeeded()
    }

    override func scrollViewDidEndDragging(
        _ scrollView: UIScrollView,
        willDecelerate decelerate: Bool
    ) {
        if !decelerate {
            updateCurrentIndexIfNeeded()
        }
    }

    // MARK: - DataSource

    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        photos.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PhotoViewerCell.reuseId,
            for: indexPath
        ) as! PhotoViewerCell

        let photo = photos[indexPath.item]
        cell.configure(with: photo.url)

        return cell
    }
}
