import Foundation
import StorageService

/// Сервис работы с постами (стена пользователя, избранное, лайки и т.д.).
/// Инкапсулирует CoreData‑слой и логику, завязанную на текущего пользователя.
protocol PostServiceProtocol {
    /// Событие "Избранное изменилось".
    var favoritesDidChange: Observable<Void> { get }

    /// Все посты на стене: свои + добавленные из главной ленты.
    func loadWallAll() async -> [MyPost]

    /// Только собственные посты текущего пользователя.
    func loadWallOwn() async -> [MyPost]

    /// Избранные посты пользователя: `filterAuthorName`: опциональный фильтр по имени автора.
    func loadFavorites(filterAuthorName: String?) async -> [MyPost]
    
    /// Добавить пост из ленты на стену текущего пользователя. Сохраняет копию `MyPost` с `ownerId = currentUser.id`.
    func addFromFeedToWall(_ post: MyPost) async

    /// Переключить лайк.
    func toggleLike(_ post: MyPost) async -> MyPost

    /// Переключить состояние "Избранное".
    func toggleFavorite(_ post: MyPost) async -> MyPost

    /// Увеличить счётчик просмотров.
    func incrementViews(_ post: MyPost) async -> MyPost

    /// Обновить (отредактировать) пост. Разрешено только для собственных постов текущего пользователя.
    func updatePost(_ post: MyPost) async throws -> MyPost

    /// Удалить пост со стены текущего пользователя.
    func deletePost(_ post: MyPost) async

    /// Обновить отображаемое имя текущего пользователя во всех его постах в CoreData. Используется, когда/если пользователь сменил имя в профиле.
    func syncCurrentUserNameInPosts() async
}

/// Реализация сервиса работы с постами, завязанная на CoreData.
final class PostService: PostServiceProtocol {

    private let storage: CDPostManagerProtocol
    private let currentUser: User

    /// Observable‑триггер изменений избранного.
    let favoritesDidChange = Observable(())

    init(
        currentUser: User,
        storage: CDPostManagerProtocol = CDPostManager()
    ) {
        self.currentUser = currentUser
        self.storage = storage
    }

    /// Возвращает все посты для ownerId = текущий пользователь.
    func loadWallAll() async -> [MyPost] {
        (try? await storage.fetchAll(ownerId: currentUser.id)) ?? []
    }

    /// Забирает все посты со стены и фильтрует по authorId (только свои посты).
    func loadWallOwn() async -> [MyPost] {
        let all = (try? await storage.fetchAll(ownerId: currentUser.id)) ?? []
        return all.filter { $0.authorId == currentUser.id }
    }

    /// Избранные посты конкретного ownerId c опциональным фильтром по имени автора.
    func loadFavorites(filterAuthorName: String?) async -> [MyPost] {
        (try? await storage.fetchFavorites(
            ownerId: currentUser.id,
            authorNameContains: filterAuthorName
        )) ?? []
    }
    /// Сохраняет пост на стену текущего пользователя.
    func addFromFeedToWall(_ post: MyPost) async {
        try? await storage.save(post: post, ownerId: currentUser.id)
    }

    /// Локально меняет флаг лайка и счётчик.
    func toggleLike(_ post: MyPost) async -> MyPost {
        var updated = post

        if updated.isLiked {
            updated.isLiked = false
            updated.likes -= 1
        } else {
            updated.isLiked = true
            updated.likes += 1
        }
        
        try? await storage.save(post: updated, ownerId: currentUser.id)

        return updated
    }

    /// В CoreData избранное хранится отдельным флагом `isFavorite`, метод меняет значение `true/false`.
    func toggleFavorite(_ post: MyPost) async -> MyPost {
        var updated = post
        updated.isFavorite.toggle()
        
        try? await storage.setFavorite(
            postId: updated.id,
            ownerId: currentUser.id,
            isFavorite: updated.isFavorite
        )
        // Уведомить подписчиков, что состав избранного изменился
        favoritesDidChange.value = ()

        return updated
    }

    /// Обновляет счётчик просмотров в хранилище.
    func incrementViews(_ post: MyPost) async -> MyPost {
        var updated = post
        updated.views += 1

        
        try? await storage.save(post: updated, ownerId: currentUser.id)

        return updated
    }

    /// Редактировать  пост (разрешено только свои).
    func updatePost(_ post: MyPost) async throws -> MyPost {
        guard post.authorId == currentUser.id else {
            return post
        }
        try await storage.save(post: post, ownerId: currentUser.id)
        
        return post
    }

    /// Удалить пост по id для текущего ownerId.
    func deletePost(_ post: MyPost) async {
        try? await storage.delete(postId: post.id, ownerId: currentUser.id)
    }

    /// Массово обновить имя автора (если вдруг изменилось) в CoreData‑постах.
    func syncCurrentUserNameInPosts() async {
        let authorId = currentUser.id
        let newName = currentUser.name.displayName

        do {
            try await storage.updateAuthorName(authorId: authorId, newName: newName)
        } catch {
            AppLogger.error("[POSTS] failed to sync author name in CoreData: \(error)")
        }
    }
}
