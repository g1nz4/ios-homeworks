import Foundation
import StorageService

/// ViewModel, отвечающая за список постов  в профиле пользователя.
@MainActor
final class ProfilePostsViewModel {
    
    /// Сервис работы с постами (загрузка, лайки, избранное и т.п.).
    private let postService: PostServiceProtocol
    
    /// Текущий список постов пользователя.
    private(set) var posts: [MyPost] = [] {
        didSet { onChanged?() }
    }
    
    /// Колбэк, который вызывается при любом изменении `posts`.
    var onChanged: (() -> Void)?
    
    /// Колбэк, который вызывается, когда изменилось состояние "избранного".
    var onFavoritesChanged: (() -> Void)?
    
    init(postService: PostServiceProtocol) {
        self.postService = postService
        
        // Подписка на глобальные изменения избранного в пост‑сервисе
        postService.favoritesDidChange.binding { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.favoritesDidChange()
            }
        }
    }
    
    /// Загружает посты пользователя (его "стену") через `postService` и сохраняет результат в `posts`.
    func loadPosts() async {
        let loaded = await postService.loadWallOwn()
        self.posts = loaded
    }
    
    /// Количество постов в текущем списке.
    var count: Int { posts.count }
    
    /// Возвращает пост по индексу, если он существует.
    func post(at index: Int) -> MyPost? {
        guard posts.indices.contains(index) else { return nil }
        return posts[index]
    }
    
    /// Поиск индекса поста по его идентификатору.
    func indexOfPost(with id: String) -> Int? {
        posts.firstIndex(where: { $0.id == id })
    }
    
    /// Вставляет новый пост в указанный индекс.
    func insert(_ post: MyPost, at index: Int) {
        let idx = min(max(index, 0), posts.count)
        posts.insert(post, at: idx)
    }
    
    /// Обновляет данные поста при редактировании.
    func update(_ post: MyPost) async {
        do {
            let updated = try await postService.updatePost(post)
            if let idx = posts.firstIndex(where: { $0.id == updated.id }) {
                posts[idx] = updated
            }
        } catch {
            AppLogger.error("[POSTS VM] update error: \(error)")
        }
    }
    
    /// Удаляет пост по индексу: сначала вызывает удаление в сервисе, затем удаляет пост из локального массива `posts`.
    func delete(at index: Int) async {
        guard posts.indices.contains(index) else { return }
        let post = posts[index]
        await postService.deletePost(post)
        posts.remove(at: index)
    }
    
    /// Переключает у поста флаг "текст развёрнут" .
    func toggleExpanded(at index: Int) {
        guard posts.indices.contains(index) else { return }
        posts[index].isExpanded.toggle()
    }
    
    /// Переключает лайк у поста по индексу.
    /// Возвращает новое состояние  и количество лайков, чтобы UI  сразу отобразил изменения.
    @discardableResult
    func toggleLike(at index: Int) async -> (isLiked: Bool, likes: Int)? {
        guard posts.indices.contains(index) else { return nil }
        let current = posts[index]
        let updated = await postService.toggleLike(current)
        posts[index] = updated
        return (updated.isLiked, updated.likes)
    }
    
    /// Инкрементирует счётчик просмотров поста  и обновляет  значение `views`, возвращая его.
    func incrementViews(at index: Int) async -> Int? {
        guard posts.indices.contains(index) else { return nil }
        let current = posts[index]
        let updated = await postService.incrementViews(current)
        posts[index] = updated
        return updated.views
    }
    
    /// Переключает состояние избранного у поста по индексу.
    func toggleFavorite(at index: Int) async {
        guard posts.indices.contains(index) else { return }
        let current = posts[index]
        let updated = await postService.toggleFavorite(current)
        posts[index] = updated
    }
    
    /// Синхронизация избранного.
    func favoritesDidChange() async {
        let favorites = await postService.loadFavorites(filterAuthorName: nil)
        let favoriteIds = Set(favorites.map { $0.id })
        
        for idx in posts.indices {
            posts[idx].isFavorite = favoriteIds.contains(posts[idx].id)
        }
        
        onFavoritesChanged?()
    }
    
    /// Локально меняет флаг избранного по id поста.
    func setFavorite(_ isFavorite: Bool, forPostId id: String) {
        for idx in posts.indices where posts[idx].id == id {
            posts[idx].isFavorite = isFavorite
            break
        }
    }
    
    /// Обновляет конкретный пост в массиве на переданную модель.
    func applyUpdatedPostFromFavorites(_ post: MyPost) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index] = post
        }
    }
}
