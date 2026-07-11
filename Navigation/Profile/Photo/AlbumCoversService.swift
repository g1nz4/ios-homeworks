import Foundation

/// Протокол загрузки обложек для альбомов(для тестов).
protocol AlbumCoversLoadingProtocol {
    /// Возвращает словарь `albumId -> URL обложки`
    func loadAlbumCovers(userId: String, albums: [PhotoAlbum]) async throws -> [String: URL]
}

/// Сервис, который подгружает обложки альбомов параллельно.
final class AlbumCoversService: AlbumCoversLoadingProtocol {

    private let userService: SupabaseUserService

    init(userService: SupabaseUserService) {
        self.userService = userService
    }

    func loadAlbumCovers(
        userId: String,
        albums: [PhotoAlbum]
    ) async throws -> [String: URL] {

        // Нет альбомов — возвращаем пустой словарь
        guard !albums.isEmpty else { return [:] }

        var covers: [String: URL] = [:]
        covers.reserveCapacity(albums.count)

        // Группа с пробросом ошибок
        try await withThrowingTaskGroup(of: (String, URL?).self) { group in
        
            for album in albums {
                group.addTask { [userService] in
                    // Если есть ошибка пробрасываем дальше
                    let photosDTO = try await userService.fetchPhotos(
                        for: userId,
                        albumId: album.id
                    )

                    // В качестве обложки берём первое фото (если есть)
                    if let first = photosDTO.first,
                       let photo = await first.toDomain() {
                        return (album.id, photo.url)
                    } else {
                        return (album.id, nil)
                    }
                }
            }

            // Сборка всех результатов
            for try await (albumId, url) in group {
                if let url {
                    covers[albumId] = url
                }
            }
        }

        return covers
    }
}
