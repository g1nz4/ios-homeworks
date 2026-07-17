import Foundation

/// Сервис работы с постами (стена пользователя, избранное, лайки и т.д.).
/// Инкапсулирует CoreData‑слой и логику, завязанную на текущего пользователя.
protocol PostServiceProtocol {
    /// Событие "Избранное изменилось".
    var favoritesDidChange: Observable<Void?> { get }
    
    /// Событие "пост обновился" (лайки, просмотры, текст и т.п.).
    var postDidUpdate: Observable<MyPost?> { get }

    /// Все посты на стене: свои + репосты. (для таба "Главная")
    func loadWallAll() async -> [MyPost]

    /// Только собственные посты текущего пользователя. (для таба "Посты")
    func loadWallOwn() async -> [MyPost]

    /// Избранные посты пользователя: `filterAuthorName`: опциональный фильтр по имени автора.
    func loadFavorites(filterAuthorName: String?) async -> [MyPost]
    
    /// Репост существующего поста на стену.
    func addFromFeedToWall(_ post: MyPost) async

    /// Переключить лайк.
    func toggleLike(_ post: MyPost) async -> MyPost

    /// Переключить состояние "Избранное".
    func toggleFavorite(_ post: MyPost) async -> MyPost

    /// Увеличить счётчик просмотров.
    func incrementViews(_ post: MyPost) async -> MyPost

    /// Создать новый пост.
    func createOwnPost(_ post: MyPost) async
    
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
    let favoritesDidChange = Observable<Void?>(nil)
    
    /// Observable обновлённого поста.
    let postDidUpdate = Observable<MyPost?>(nil)
    
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
    /// Сохраняет пост текущего пользователя.
    func addFromFeedToWall(_ post: MyPost) async {
        var wallPost = post
        wallPost.isOnWall = true
        try? await storage.save(post: wallPost, ownerId: currentUser.id)
        postDidUpdate.value = wallPost
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
        postDidUpdate.value = updated
        
        return updated
    }
    
    /// В CoreData избранное хранится отдельным флагом `isFavorite`, метод меняет значение `true/false`.
    @MainActor
    func toggleFavorite(_ post: MyPost) async -> MyPost {
        var updated = post
        let wasFavorite = updated.isFavorite
        updated.isFavorite.toggle()
        
        if !post.isOnWall && !wasFavorite && updated.isFavorite {
            updated.isOnWall = false
            // upsert‑сохранение поста с флагом избранного
            try? await storage.save(post: updated, ownerId: currentUser.id)
        } else {
            // пост уже есть в CoreData: изменить флаг избранного
            try? await storage.setFavorite(
                postId: updated.id,
                ownerId: currentUser.id,
                isFavorite: updated.isFavorite
            )
        }
        
        favoritesDidChange.value = ()
        postDidUpdate.value = updated
        
        return updated
    }
    
    /// Обновляет счётчик просмотров в хранилище.
    func incrementViews(_ post: MyPost) async -> MyPost {
        var updated = post
        updated.views += 1
        
        try? await storage.save(post: updated, ownerId: currentUser.id)
        postDidUpdate.value = updated
        
        return updated
    }
    
    func createOwnPost(_ post: MyPost) async {
        var wallPost = post
        wallPost.isOnWall = true
        try? await storage.save(post: wallPost, ownerId: currentUser.id)
        postDidUpdate.value = wallPost
    }
    
    /// Редактировать  пост (разрешено только свои).
    func updatePost(_ post: MyPost) async throws -> MyPost {
        guard post.authorId == currentUser.id else {
            return post
        }
        try await storage.save(post: post, ownerId: currentUser.id)
        postDidUpdate.value = post 
        
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
