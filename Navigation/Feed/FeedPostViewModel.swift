import Foundation

/// ViewModel, отвечающий за работу с постами в ленте:
/// 1.  загрузка постов
/// 2.  лайки / избранное / просмотры
/// 3.  подписка на внешние обновления постов
@MainActor
final class FeedPostsViewModel {

    private let feedService: LocalFeedServiceProtocol
    private let postService: PostServiceProtocol
    private let photosRepository: PhotosRepositoryProtocol

    /// Текущий массив постов в ленте
    private(set) var posts: [MyPost] = []

    /// Текущий пользователь
    let currentUser: User

    /// Коллбэк для контроллера: какие индексы постов изменились.
    var onPostsUpdated: (([Int]) -> Void)?

    /// ID подписки на Observable постов.
    private var postDidUpdateBindingId: UUID?

    init(
        feedService: LocalFeedServiceProtocol,
        postService: PostServiceProtocol,
        photosRepository: PhotosRepositoryProtocol,
        currentUser: User
    ) {
        self.feedService = feedService
        self.postService = postService
        self.photosRepository = photosRepository
        self.currentUser = currentUser

        observePostUpdates()
    }

    /// Загрузка ленты постов пользователя.
    func load() async {
        do {
            let fetched = try await feedService.fetchFeed(for: currentUser.id)
            posts = fetched
            onPostsUpdated?(Array(posts.indices))
        } catch {
            AppLogger.error("[FEED] Failed to load posts: \(error)")
        }
    }

    func numberOfItems() -> Int { posts.count }

    func post(at index: Int) -> MyPost { posts[index] }

    /// Переключение лайка для поста по индексу.
    func toggleLike(at index: Int) async {
        guard posts.indices.contains(index) else { return }
        let post = posts[index]

        let updated = await postService.toggleLike(post)
        applyUpdatedPost(updated)
    }

    /// Переключение избранного для поста по индексу.
    func toggleFavorite(at index: Int) async {
        guard posts.indices.contains(index) else { return }
        let post = posts[index]

        let updated = await postService.toggleFavorite(post)
        applyUpdatedPost(updated)
    }

    /// Репост поста на стену пользователя.
    func addPostToWall(at index: Int) async {
        guard posts.indices.contains(index) else { return }
        let post = posts[index]

        await postService.addFromFeedToWall(post)
    }

    /// Инкремент счётчика просмотров поста.
    func incrementViews(at index: Int) async {
        guard posts.indices.contains(index) else { return }
        let post = posts[index]

        let updated = await postService.incrementViews(post)
        applyUpdatedPost(updated)
    }

    /// Локальное переключение флага "развернут" для текста поста.
    func toggleExpanded(at index: Int) {
        guard posts.indices.contains(index) else { return }
        var post = posts[index]
        post.isExpanded.toggle()
        posts[index] = post
        onPostsUpdated?([index])
    }

    /// Добавление фото в "Сохранённые".
    func addToSaved(photo: Photo) async {
        let url = photo.url

        do {
            try await photosRepository.addPhotoToSaved(
                userId: currentUser.id,
                photoURL: url
            )
        } catch {
            AppLogger.error("[FEED] addToSaved failed for photo \(photo.id): \(error)")
        }
    }

    /// Обновление локального массива постов и уведомление об изменении конкретного индекса.
    private func applyUpdatedPost(_ updated: MyPost) {
        guard let index = posts.firstIndex(where: { $0.id == updated.id }) else { return }
        posts[index] = updated
        onPostsUpdated?([index])
    }

    /// Подписка на глобальные обновления постов из postService.
    private func observePostUpdates() {
        postDidUpdateBindingId = postService.postDidUpdate.binding { [weak self] updatedPost in
            guard let self = self, let updated = updatedPost else { return }

            if let idx = self.posts.firstIndex(where: { $0.id == updated.id }) {
                self.posts[idx] = updated
                self.onPostsUpdated?([idx])
            }
        }
    }
}
