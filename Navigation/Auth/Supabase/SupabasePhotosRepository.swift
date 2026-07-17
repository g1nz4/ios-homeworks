import Foundation

/// Абстракция репозитория для работы с фото/альбомами.
/// Позволяет скрыть детали SupabaseUserService и использовать доменные модели.
protocol PhotosRepositoryProtocol {
    /// Загрузить все альбомы пользователя.
    func loadAlbums(for userId: String) async throws -> [PhotoAlbum]
    /// Загрузить список фотографий пользователя (по альбому или без него).
    func loadPhotos(userId: String, albumId: String?) async throws -> [Photo]
    /// Удалить фото по идентификатору.
    func deletePhoto(id: String) async throws
    /// Установить фото аватаром профиля.
    func setAvatarFromPhoto(userId: String, photoURL: URL) async throws
    /// Установить обложку из фото.
    func setCoverFromPhoto(userId: String, photoURL: URL) async throws
    /// Добавить фото в альбом "Сохранённые".
    func addPhotoToSaved(userId: String, photoURL: URL) async throws
}

/// Репозиторий фотографий поверх `SupabaseUserService`. На уровне репозитория происходит маппинг DTO -> доменные модели.
final class SupabasePhotosRepository: PhotosRepositoryProtocol {
    
    /// Сервис работы с профилями и фото в Supabase.
    private let userService: SupabaseUserService

    init(userService: SupabaseUserService) {
        self.userService = userService
    }

    func loadAlbums(for userId: String) async throws -> [PhotoAlbum] {
        try await userService.fetchPhotoAlbums(for: userId).map { $0.toDomain() }
    }

    func loadPhotos(userId: String, albumId: String?) async throws -> [Photo] {
        try await userService.fetchPhotos(for: userId, albumId: albumId).compactMap { $0.toDomain() }
    }

    func deletePhoto(id: String) async throws {
        try await userService.deletePhoto(photoId: id)
    }

    func setAvatarFromPhoto(userId: String, photoURL: URL) async throws {
        try await userService.setAvatarFromPhoto(userId: userId, photoURL: photoURL)
    }

    func setCoverFromPhoto(userId: String, photoURL: URL) async throws {
        try await userService.setCoverFromPhoto(userId: userId, photoURL: photoURL)
    }

    func addPhotoToSaved(userId: String, photoURL: URL) async throws {
        AppLogger.debug("[REPO] addPhotoToSaved userId=\(userId) url=\(photoURL)")
        try await userService.addPhotoToSaved(userId: userId, photoURL: photoURL)
    }
}



