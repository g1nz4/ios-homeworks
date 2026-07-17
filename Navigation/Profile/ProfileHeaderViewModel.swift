import Foundation

/// ViewModel для хедера профиля: данные пользователя, аватар, обложка, наличие сторис и т.п.
@MainActor
final class ProfileHeaderViewModel {
    
    /// Текущий пользователь профиля.
    private(set) var user: User {
        didSet { onUserChanged?(user) }
    }
    
    /// Флаг, есть ли у пользователя сторис.
    private(set) var hasStory: Bool = false
    
    /// Сервис для загрузки и обновления профиля пользователя (Supabase).
    private let userService: SupabaseUserService
    
    /// Хранилище сторис.
    private let storyStorage: CDStoryStorageProtocol
    
    /// Вызывается при каждом обновлении `user`.
    var onUserChanged: ((User) -> Void)?
    
    /// Вызывается при ошибках загрузки/обновления профиля.
    var onError: ((AppError) -> Void)?
    
    /// Вызывается при изменении `hasStory`.
    var onStoryFlagChanged: ((Bool) -> Void)?
    
    /// Геттер для URL аватара пользователя.
    var avatarURL: URL? {
        user.avatarURL
    }
    
    init(
        user: User,
        userService: SupabaseUserService,
        storyStorage: CDStoryStorageProtocol
    ) {
        self.user = user
        self.userService = userService
        self.storyStorage = storyStorage
    }
    
    /// Загружает профиль пользователя с сервера и обновляет `user`.
    func loadProfile() async {
        do {
            let fetched = try await userService.fetchProfile(userID: user.id)
            self.user = fetched
        } catch {
            onError?(AppError.profileLoadingFailed)
        }
    }
    
    /// Перезагружает профиль пользователя и флаг наличия сторис.
    func reloadProfile() async {
        await loadProfile()
        await updateStoryFlag()
    }
    
    /// Локально обновляет модель пользователя (без запроса к сети).
    func update(with user: User) {
        self.user = user
        onUserChanged?(user)
    }
    
    /// Устанавливает новый аватар из выбранного `Photo`.
    func setAvatar(from photo: Photo) async {
        do {
            try await userService.setAvatarFromPhoto(
                userId: user.id,
                photoURL: photo.url
            )
            await reloadProfile()
        } catch {
            AppLogger.error("[HEADER] setAvatar error: \(error)")
        }
    }
    
    /// Устанавливает новую обложку профиля (cover) из выбранного `Photo`.
    func setCover(from photo: Photo) async {
        do {
            try await userService.setCoverFromPhoto(
                userId: user.id,
                photoURL: photo.url
            )
            await reloadProfile()
        } catch {
            AppLogger.error("[HEADER] setCover error: \(error)")
        }
    }
    
    /// Обновляет флаг `hasStory`, проверяя наличие последней сторис в локальном хранилище для текущего пользователя.
    private func updateStoryFlag() async {
        do {
            let loaded = try await storyStorage.loadLastStory(for: user.id)
            let has = !(loaded?.items.isEmpty ?? true)
            self.hasStory = has
            onStoryFlagChanged?(has)
        } catch {
            self.hasStory = false
            onStoryFlagChanged?(false)
        }
    }
}
