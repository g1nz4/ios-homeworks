import Foundation

/// ViewModel экрана "Избранное".
@MainActor
final class FavoritesViewModel {

    /// Сервис работы с постами.
    private let postService: PostServiceProtocol

    /// Множество id постов, которые сейчас в состоянии "развёрнутый текст".
    private var expandedPostIds: Set<String> = []

    /// Текущий список избранных постов.
    private(set) var posts: [MyPost] = []
    
    /// Текущий фильтр по автору.
    private var currentAuthorFilter: String?

    /// Вызывается, когда нужно перерисовать весь список (первичная загрузка, поиск).
    var onPostsChanged: (([MyPost]) -> Void)?

    init(postService: PostServiceProtocol) {
        self.postService = postService
        
        // Подписка на событие "избранное изменилось"
        postService.favoritesDidChange.binding { [weak self] _ in
            guard let self else { return }
          
            Task { @MainActor in
                let items = await self.postService.loadFavorites(
                    filterAuthorName: self.currentAuthorFilter
                )
                self.posts = items
                self.onPostsChanged?(items)
            }
        }
        
        postService.postDidUpdate.binding { [weak self] updatedPost in
            guard let self, let updatedPost else { return }
           
            Task { @MainActor [weak self] in
                self?.handlePostDidUpdate(updatedPost)
            }
        }
    }

    /// Загружает все избранные посты без фильтра.
    func loadFavorites() async {
        currentAuthorFilter = nil
        let items = await postService.loadFavorites(filterAuthorName: nil)
        posts = items
        onPostsChanged?(items)
    }

    /// Задаёт фильтр по имени автора и перезагружает избранные посты.
    func setFilter(author: String?) async {
        currentAuthorFilter = author
        let items = await postService.loadFavorites(filterAuthorName: author)
        posts = items
        onPostsChanged?(items)
    }

    /// Переключает лайк для поста по индексу.
    @discardableResult
    func toggleLike(at index: Int) async -> MyPost? {
        guard posts.indices.contains(index) else { return nil }

        let post = posts[index]
        let updated = await postService.toggleLike(post)
        posts[index] = updated

        return updated
    }

    /// Удаляет пост из избранного по индексу.
    @discardableResult
    func removeFromFavorites(at index: Int) async -> String? {
        guard posts.indices.contains(index) else { return nil }

        let post = posts[index]

        // Переключить флаг избранного в сервисе
        _ = await postService.toggleFavorite(post)

        // Локально убрать пост из списка избранного
        posts.remove(at: index)

        // Очистить локальное состояние
        expandedPostIds.remove(post.id)

        return post.id
    }
    
    private func handlePostDidUpdate(_ updatedPost: MyPost) {
        // Поиск поста в избранных
        guard let index = posts.firstIndex(where: { $0.id == updatedPost.id }) else {
            return
        }

        posts[index] = updatedPost
        onPostsChanged?(posts)
    }

    /// Проверяет, развернут ли текст поста с переданным id.
    func isExpanded(postId: String) -> Bool {
        expandedPostIds.contains(postId)
    }

    /// Переключает локальное состояние разворота поста.
    func toggleExpanded(postId: String) {
        if expandedPostIds.contains(postId) {
            expandedPostIds.remove(postId)
        } else {
            expandedPostIds.insert(postId)
        }
    }
    
    func addPostToWall(at index: Int) async {
        guard posts.indices.contains(index) else { return }
        let post = posts[index]
        await postService.addFromFeedToWall(post)
       
    }
}
