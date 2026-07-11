import Foundation
import StorageService

/// ViewModel экрана "Избранное".
@MainActor
final class FavoritesViewModel {

    /// Сервис работы с постами.
    private let postService: PostServiceProtocol

    /// Множество id постов, которые сейчас в состоянии "развёрнутый текст".
    private var expandedPostIds: Set<String> = []

    /// Текущий список избранных постов.
    private(set) var posts: [MyPost] = []

    /// Вызывается, когда нужно перерисовать весь список (первичная загрузка, поиск).
    var onPostsChanged: (([MyPost]) -> Void)?

    init(postService: PostServiceProtocol) {
        self.postService = postService
    }

    /// Загружает все избранные посты без фильтра.
    func loadFavorites() async {
        let items = await postService.loadFavorites(filterAuthorName: nil)
        posts = items
        onPostsChanged?(items)
    }

    /// Задаёт фильтр по имени автора и перезагружает избранные посты.
    func setFilter(author: String?) async {
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

        // Локально убирать пост из списка избранного
        posts.remove(at: index)

        // Очистить локальное состояние
        expandedPostIds.remove(post.id)

        return post.id
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
}
