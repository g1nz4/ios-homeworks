import UIKit

/// Обратная связь от хэндлера коллекции к контроллеру профиля / координатору.
protocol ProfileCollectionHandlerOutput: AnyObject {
    func didScrollProfile(offsetY: CGFloat)

    func didSelectFriends()
    func didSelectPublish()
    func didSelectAlbum(_ album: PhotoAlbum)
    func didSelectPhoto(at index: Int, allPhotos: [Photo])
    func didSelectStory(hasStory: Bool)

    func didTapEditPost(_ post: MyPost)
    func didTapDeletePost(at index: Int)
    func didToggleFavorite(postIndex: Int, cell: PostCollectionViewCell)

    func incrementViewsForPost(at index: Int, cell: PostCollectionViewCell)
    func toggleLikeForPost(at index: Int, cell: PostCollectionViewCell)

    func didTapAvatarWithoutStory()
    func didTapMoreInfo()
    func didTapPostImage(photo: Photo)
    func didTapSharePost(at index: Int)
}

/// Отдельный объект, который реализует dataSource/delegate коллекции профиля.
/// Хранит минимум состояния и общается с ProfileViewModel + ProfileViewController.
final class ProfileCollectionHandler: NSObject {

    private let viewModel: ProfileViewModel
    weak var output: ProfileCollectionHandlerOutput?

    /// Текущий пользователь (для конфигурации ячеек постов и хедера).
    private var currentUser: User?
    /// Есть ли активная сторис у пользователя.
    private var hasCurrentStory = false
    /// Текущий верхний safe‑inset (для кастомного header’а).
    private var topSafeInset: CGFloat = 0

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    /// Передаёт в хэндлер актуального пользователя.
    func updateUser(_ user: User) {
        currentUser = user
    }

    /// Обновляет флаг наличия сторис.
    func updateHasStory(_ hasStory: Bool) {
        hasCurrentStory = hasStory
    }

    /// Обновляет верхний safe‑inset, чтобы header мог корректно сдвигаться.
    func updateTopInset(_ inset: CGFloat) {
        topSafeInset = inset
    }
}

// MARK: - UICollectionViewDataSource

extension ProfileCollectionHandler: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        viewModel.numberOfSections()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        viewModel.numberOfRows(in: section)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let type = viewModel.cellType(for: indexPath.section, item: indexPath.item)

        switch type {

        case .friends:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: FriendsCollectionViewCell.reuseId,
                for: indexPath
            ) as! FriendsCollectionViewCell
            let summary = viewModel.friendsSummary()
            cell.configure(
                friendsCount: summary.count,
                avatarURLs: summary.avatars
            )
            
            return cell

        case .publish:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PublishCapsuleCollectionViewCell.reuseId,
                for: indexPath
            ) as! PublishCapsuleCollectionViewCell
            
            return cell

        case .posts:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PostCollectionViewCell.reuseId,
                for: indexPath
            ) as! PostCollectionViewCell

            guard
                let post = viewModel.post(section: indexPath.section, item: indexPath.item),
                let user = currentUser
            else {
                return cell
            }

            cell.configure(with: post, user: user)
            cell.delegate = self

            let postIndex = indexPath.item - 1
            let canEdit = post.authorId == user.id
            
            cell.configureMenu(
                isFavorite: post.isFavorite,
                onFavorite: { [weak self, weak cell] in
                    guard let self, let cell else { return }
                    self.output?.didToggleFavorite(postIndex: postIndex, cell: cell)
                },
                onEdit: canEdit ? { [weak self] in
                    guard
                        let self,
                        let post = self.viewModel.post(
                            section: indexPath.section,
                            item: indexPath.item
                        )
                    else { return }
                    self.output?.didTapEditPost(post)
                } : nil,
                onDelete: { [weak self] in
                    self?.output?.didTapDeletePost(at: postIndex)
                }
            )
            
            cell.setShareButtonHidden(true)

            return cell

        case .photoAlbums:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: AlbumCell.reuseId,
                for: indexPath
            ) as! AlbumCell

            if let album = viewModel.album(at: indexPath.item) {
                let coverURL = viewModel.coverURL(forAlbumAt: indexPath.item)
                cell.configure(with: album, coverURL: coverURL)
            }
            
            return cell

        case .photoItem:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PhotoCell.reuseId,
                for: indexPath
            ) as! PhotoCell

            if let photo = viewModel.photoItem(at: indexPath.item) {
                cell.configure(with: photo.url)
            }
            
            return cell

        case .tabs:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ProfileTabsCell.reuseId,
                for: indexPath
            ) as! ProfileTabsCell

            cell.configure(selectedTab: viewModel.currentTab)
            cell.onSelectTab = { [weak self] tab in
                guard let self else { return }
                Task { [weak self] in
                    guard let self else { return }
                    await self.viewModel.selectTab(tab)
                }
            }
            
            return cell

        case .emptyMessage:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: EmptyMessageCell.reuseId,
                for: indexPath
            ) as! EmptyMessageCell
            cell.configure(for: viewModel.currentTab)
            
            return cell

        case .none:
            return UICollectionViewCell()
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }

        switch indexPath.section {

        // Хедер профиля
        case 0:
            guard
                let header = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: ProfileHeaderView.reuseId,
                    for: indexPath
                ) as? ProfileHeaderView
            else {
                return UICollectionReusableView()
            }

            if let user = currentUser {
                header.configureHeader(with: user, imageLoader: ImageLoader.shared)
                header.setHasStory(hasCurrentStory)
            }
            header.setTopInset(topSafeInset)
            
            header.onTapStory = { [weak self] in
                guard let self else { return }
                self.output?.didSelectStory(hasStory: self.hasCurrentStory)
            }

            header.onTapAvatar = { [weak self] in
                self?.output?.didTapAvatarWithoutStory()
            }

            header.onTapMore = { [weak self] in
                self?.output?.didTapMoreInfo()
            }

            return header

        // Заголовок секции "Альбомы" (в photos табе)
        case 2:
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: ProfileSectionTitleView.reuseId,
                for: indexPath
            ) as! ProfileSectionTitleView
            header.configure(title: "Альбомы")
            return header

        // Заголовок секции "Фотографии"
        case 3:
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: ProfileSectionTitleView.reuseId,
                for: indexPath
            ) as! ProfileSectionTitleView
            header.configure(title: "Фотографии")
            return header

        default:
            return UICollectionReusableView()
        }
    }
}

// MARK: - UICollectionViewDelegate

extension ProfileCollectionHandler: UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let type = viewModel.cellType(for: indexPath.section, item: indexPath.item)

        switch type {
        case .friends:
            output?.didSelectFriends()

        case .publish:
            output?.didSelectPublish()

        case .photoAlbums:
            if let album = viewModel.album(at: indexPath.item) {
                output?.didSelectAlbum(album)
            }

        case .photoItem:
            let photos = viewModel.allPhotos()
            output?.didSelectPhoto(at: indexPath.item, allPhotos: photos)

        default:
            break
        }

        collectionView.deselectItem(at: indexPath, animated: true)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        // Учёт просмотров постов: только на главной вкладке, секция 1, item > 0 (после табов)
        guard
            viewModel.currentTab == .main,
            indexPath.section == 1,
            indexPath.item > 0,
            let postCell = cell as? PostCollectionViewCell
        else { return }

        let postIndex = indexPath.item - 1
        output?.incrementViewsForPost(at: postIndex, cell: postCell)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Смещение с учётом adjustedInset — для анимации тайтла в навбаре
        let offsetY = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        output?.didScrollProfile(offsetY: offsetY)
    }
}

// MARK: - PostCollectionViewCellDelegate

extension ProfileCollectionHandler: PostCollectionViewCellDelegate {
    
    func postCellDidTapMore(_ cell: PostCollectionViewCell) {
        guard
            let collectionView = findCollectionView(from: cell),
            let indexPath = collectionView.indexPath(for: cell)
        else { return }
        
        let postIndex = indexPath.item - 1
        
        viewModel.toggleExpandedForPost(at: postIndex)
        
        UIView.performWithoutAnimation {
            collectionView.performBatchUpdates({
                collectionView.reloadItems(at: [indexPath])
                collectionView.layoutIfNeeded()
            }, completion: { _ in
                collectionView.scrollToItem(
                    at: indexPath,
                    at: .top,
                    animated: false
                )
            })
        }
    }

    func postCellDidTapLike(_ cell: PostCollectionViewCell) {
        guard
            let collectionView = findCollectionView(from: cell),
            let indexPath = collectionView.indexPath(for: cell)
        else { return }

        let postIndex = indexPath.item - 1
        output?.toggleLikeForPost(at: postIndex, cell: cell)
    }

    func postCellDidTapImage(_ cell: PostCollectionViewCell) {
        guard
            let collectionView = findCollectionView(from: cell),
            let indexPath = collectionView.indexPath(for: cell),
            let post = viewModel.post(section: indexPath.section, item: indexPath.item)
        else { return }

        // Взять URL из imagePath
        guard
            let path = post.imagePath,
            !path.isEmpty,
            let url = URL(string: path)
        else {
            AppLogger.debug("[PROFILE] postCellDidTapImage: no valid image url for post \(post.id)")
            return
        }

        // Сборка Photo для вьюера
        let photo = Photo(id: post.id, url: url, albumId: nil)

        // Проброс наверх в контроллер профиля
        output?.didTapPostImage(photo: photo)
    }
    
    func postCellDidTapShare(_ cell: PostCollectionViewCell) { }
    
    /// Ищет `UICollectionView`, к которой принадлежит ячейка.
    private func findCollectionView(from cell: UICollectionViewCell) -> UICollectionView? {
        var view: UIView? = cell.superview
        while view != nil && !(view is UICollectionView) {
            view = view?.superview
        }
        return view as? UICollectionView
    }
}
