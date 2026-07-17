import Foundation
import UIKit

/// Протокол сервиса работы с профилями пользователей (для тестов).
protocol UserServiceProtocol: AnyObject {
    /// Создать профиль для пользователя.
    func createProfile(for user: User) async throws
    /// Загрузить профиль по `userID` (UUID из Supabase Auth).
    func fetchProfile(userID: String) async throws -> User
    /// Загрузить профиль по номеру телефона.
    func fetchProfile(phone: String) async throws -> User
    /// Обновить профиль пользователя и вернуть свежие пользовательские данные.
    func updateProfile(user: User) async throws -> User
    /// Загрузить список друзей пользователя по его userId.
    func fetchFriends(for userId: String) async throws -> [User]
}

/// Сервис для работы с таблицей profiles в Supabase.
final class SupabaseUserService: UserServiceProtocol {
    
    /// REST‑клиент Supabase.
    private let client: SupabaseRESTClient
    /// Хранилище кешированных пользователей (CoreData).
    private let cacheStore: CDUserCache
    
    init(
        client: SupabaseRESTClient,
        cacheStore: CDUserCache
    ) {
        self.client = client
        self.cacheStore = cacheStore
    }
    
    /// Создать или обновить профиль в таблице Supabase profiles.
    func createProfile(for user: User) async throws {
        let dto = UserProfileDTO(from: user)
        let data = try client.encode([dto])
        
        var request = client.makeRESTRequest(
            path: "profiles",
            method: "POST",
            body: data
        )
        // чтобы не дублировать записи
        request.addValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        
        try await client.performVoid(request)
    }
    
    /// Загрузить профиль по id (uuid из Supabase Auth). По userID (для логина по email/паролю).
    func fetchProfile(userID: String) async throws -> User {
        let queryItems = [
            URLQueryItem(name: "id", value: "eq.\(userID)"),
            URLQueryItem(name: "select", value: "*")
        ]
        
        let request = client.makeRESTRequest(
            path: "profiles",
            queryItems: queryItems
        )
        
        let dtos: [UserProfileDTO] = try await client.perform(request)
        guard let dto = dtos.first else {
            throw AppError.profileNotFound
        }
        
        let user = dto.toDomain()
        AppLogger.debug(
           """
            User from Supabase: \( user.id)
            first: \(user.name.firstName)
            last: \(user.name.lastName)
           """
           )
        do {
            try await cacheStore.save(user)
        } catch {
            AppLogger.debug("UserCache save error: \(error)")
        }
        
        return user
    }
    
    /// Загрузить профиль по телефону (для логина по телефону).
    func fetchProfile(phone: String) async throws -> User {
        let queryItems = [
            URLQueryItem(name: "phone", value: "eq.\(phone)"),
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "limit", value: "1")
        ]
        
        let request = client.makeRESTRequest(
            path: "profiles",
            queryItems: queryItems
        )
        
        let dtos: [UserProfileDTO] = try await client.perform(request)
        guard let dto = dtos.first else {
            throw AppError.profileNotFound
        }
        
        let user = dto.toDomain()
        AppLogger.debug(
           """
            User from Supabase: \( user.id)
            first: \(user.name.firstName)
            last: \(user.name.lastName)
           """
        )
        do {
            try await cacheStore.save(user)
        } catch {
            AppLogger.debug("UserCache save error: \(error)")
        }
        
        return user
    }
    
    /// Обновляет профиль пользователя:
    /// Берет "старую" версию пользователя из кеша или с сервера. Собирает body только из действительно изменённых полей. Отправляет PATCH в Supabase. Перечитывает свежую версию с сервера и обновляет кеш.
    func updateProfile(user: User) async throws -> User {
        // "Старая" версия данных
        let oldUser: User
        if let cached = try? await cacheStore.load(userID: user.id) {
            oldUser = cached
        } else {
            oldUser = try await fetchProfile(userID: user.id)
        }

        // body только по изменённым полям
        var body: [String: Any] = [:]

        if oldUser.nickname != user.nickname {
            body["nickname"] = user.nickname ?? NSNull()
        }
        if oldUser.city != user.city {
            body["city"] = user.city ?? NSNull()
        }
        if oldUser.status != user.status {
            body["status"] = user.status ?? NSNull()
        }
        if oldUser.about != user.about {
            body["about"] = user.about ?? NSNull()
        }
        if oldUser.name != user.name {
            body["first_name"] = user.name.firstName
            body["last_name"]  = user.name.lastName
        }
        if oldUser.gender != user.gender {
            body["gender"] = user.gender.rawValue
        }
        if oldUser.birthDate != user.birthDate {
            if let date = user.birthDate {
                let iso = ISO8601DateFormatter()
                iso.formatOptions = [.withFullDate]
                body["birth_date"] = iso.string(from: date)
            } else {
                body["birth_date"] = NSNull()
            }
        }

        guard !body.isEmpty else {
            return oldUser
        }

        // PATCH на сервер
        try await updateProfileFields(userId: user.id, body: body)

        // Загрузка свежей версий с сервера
        let fresh = try await fetchProfile(userID: user.id)

        // После успешного ответа – обновить кеш
        do {
            try await cacheStore.save(fresh)
        } catch {
            AppLogger.debug("UserCache save error: \(error)")
        }

        return fresh
    }
    
    /// Загружает список друзей для заданного пользователя.
    ///
    /// 1. Чтение таблицы `friendships`, где user_id = userId или friend_id = userId,  и статус дружбы = accepted.
    /// 2. Извлечение id друзей (второй стороны дружбы).
    /// 3. Запрос в `profiles` по списку id через оператор `in`.
    func fetchFriends(for userId: String) async throws -> [User] {
        let queryItems = [
            URLQueryItem(
                name: "or",
                value: "(user_id.eq.\(userId),friend_id.eq.\(userId))"
            ),
            URLQueryItem(name: "status", value: "eq.accepted"),
            URLQueryItem(name: "select", value: "*")
        ]
        
        let request = client.makeRESTRequest(
            path: "friendships",
            queryItems: queryItems
        )
        
        let friendships: [FriendshipDTO] = try await client.perform(request)
        if friendships.isEmpty { return [] }
        
        // получить список id друзей
        let friendIDs: [String] = friendships.map { f in
            f.userId == userId ? f.friendId : f.userId
        }
        
        let idsList = friendIDs.joined(separator: ",")
        
        let profilesRequest = client.makeRESTRequest(
            path: "profiles",
            queryItems: [
                URLQueryItem(name: "id", value: "in.(\(idsList))"),
                URLQueryItem(name: "select", value: "*")
            ]
        )
        
        let dtos: [UserProfileDTO] = try await client.perform(profilesRequest)
        let users = dtos.map { $0.toDomain() }
        return users
    }
    
    /// Установить аватар из уже загруженного в Supabase фото.
    func setAvatarFromPhoto(userId: String, photoURL: URL) async throws {
        AppLogger.debug("[SERVICE] setAvatarFromPhoto url=\(photoURL)")
        
        // Обновить профиль
        try await updateProfileFields(
            userId: userId,
            avatarUrl: photoURL.absoluteString,
            coverUrl: nil
        )
        
        // Синхронизировать альбом "Фото со страницы"
        do {
            try await syncAvatarToProfileAlbum(userId: userId, photoURL: photoURL)
        } catch {
            AppLogger.error("[PHOTOS] failed to sync profile album with avatar: \(error)")
        }
        
        //  только coverURL в кеш
        if let cached = try await cacheStore.load(userID: userId) {
            cached.avatarURL = photoURL
            try await cacheStore.save(cached)
        }
    }
    
    /// Установить обложку профиля (cover) по URL уже загруженной фотки.
    func setCoverFromPhoto(userId: String, photoURL: URL) async throws {
        AppLogger.debug("[SERVICE] setCoverFromPhoto url=\(photoURL)")
        
        try await updateProfileFields(
            userId: userId,
            body: ["cover_url": photoURL.absoluteString]
        )
        
        // только coverURL в кеш
        if let cached = try await cacheStore.load(userID: userId) {
            cached.coverURL = photoURL
            try await cacheStore.save(cached)
        }
    }
    
    /// PATCH профиля по `userId` и произвольному JSON‑body.
    private func updateProfileFields(userId: String, body: [String: Any]) async throws {
        AppLogger.debug("[PROFILE] raw PATCH body = \(body)")
        
        let data = try JSONSerialization.data(withJSONObject: body, options: [])
        let request = client.makeRESTRequest(
            path: "profiles",
            method: "PATCH",
            queryItems: [URLQueryItem(name: "id", value: "eq.\(userId)")],
            body: data
        )
        try await client.performVoid(request)
    }
    
    /// Перегрузка для PATCH только `avatar_url` и/или `cover_url`.
    private func updateProfileFields(
        userId: String,
        avatarUrl: String?,
        coverUrl: String?
    ) async throws {
        var body: [String: Any] = [:]
        if let avatarUrl {
            body["avatar_url"] = avatarUrl
        }
        if let coverUrl {
            body["cover_url"] = coverUrl
        }
        guard !body.isEmpty else { return }
        
        AppLogger.debug(
            "[PROFILE] PATCH avatarUrl =\(String(describing: avatarUrl)) " +
            "coverUrl=\(String(describing: coverUrl)) body =\(body)"
        )
        
        try await updateProfileFields(userId: userId, body: body)
    }
    
    /// Загрузить все фотоальбомы пользователя.
    func fetchPhotoAlbums(for userId: String) async throws -> [PhotoAlbumDTO] {
        let queryItems = [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "created_at.asc")
        ]
        
        let request = client.makeRESTRequest(
            path: "photo_albums",
            queryItems: queryItems
        )
        
        let albums: [PhotoAlbumDTO] = try await client.perform(request)
        AppLogger.debug("[PHOTOS] albums = \(albums)")
        return albums
    }
    
    /// Загрузить список фотографий пользователя: ` userId`: владелец фотографий,`albumId`: идентификатор альбома, либо `nil` для фото без альбома.
    func fetchPhotos(for userId: String, albumId: String?) async throws -> [PhotoDTO] {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ]
        
        if let albumId {
            queryItems.append(URLQueryItem(name: "album_id", value: "eq.\(albumId)"))
        } else {
            queryItems.append(URLQueryItem(name: "album_id", value: "is.null"))
        }
        
        let request = client.makeRESTRequest(
            path: "photos",
            queryItems: queryItems
        )
        
        let photos: [PhotoDTO] = try await client.perform(request)
        return photos
    }
    
    /// Добавить фото в альбом "Сохранённые" (type = "saved").
    func addPhotoToSaved(userId: String, photoURL: URL) async throws {
        AppLogger.debug("[SAVED] addPhotoToSaved url =\(photoURL)")
        
        // Поиск альбома type = "saved"
        let albums = try await fetchPhotoAlbums(for: userId)
        guard let savedAlbum = albums.first(where: { $0.type == "saved" }) else {
            AppLogger.error("[SAVED] saved album not found for user \(userId)")
            return
        }
        
        // Проверка наличия такого URL в  альбоме
        let savedPhotos = try await fetchPhotos(for: userId, albumId: savedAlbum.id)
        if savedPhotos.contains(where: { $0.url == photoURL.absoluteString }) {
            AppLogger.debug("[SAVED] photo already in saved album")
            return
        }
        
        // Добавить запись в таблицу `photos`
        do {
            try await insertPhoto(
                userId: userId,
                albumId: savedAlbum.id,
                url: photoURL
            )
        } catch {
            AppLogger.error("[SAVED] insertPhoto error: \(error)")
            throw error
        }
    }

    /// Удалить одну фотографию по идентификатору.
    func deletePhoto(photoId: String) async throws {
        let queryItems = [
            URLQueryItem(name: "id", value: "eq.\(photoId)")
        ]
        
        let request = client.makeRESTRequest(
            path: "photos",
            method: "DELETE",
            queryItems: queryItems
        )
        
        try await client.performVoid(request)
    }
    
    // MARK: - Внутренние helpers для photos
    
    /// Убедиться, что фото‑аватар присутствует в альбоме type = "profile" (альбом "Фото со страницы"). Если фото уже там — ничего не делать.
    private func syncAvatarToProfileAlbum(userId: String, photoURL: URL) async throws {
        let albums = try await fetchPhotoAlbums(for: userId)
        guard let profileAlbum = albums.first(where: { $0.type == "profile" }) else {
            AppLogger.error("[PHOTOS] profile album not found for user \(userId)")
            return
        }
        
        let existing = try await fetchPhotos(for: userId, albumId: profileAlbum.id)
        if existing.contains(where: { $0.url == photoURL.absoluteString }) {
            AppLogger.debug("[PHOTOS] avatar photo already in profile album")
            return
        }
        
        try await insertPhoto(
            userId: userId,
            albumId: profileAlbum.id,
            url: photoURL
        )
    }
}

private extension SupabaseUserService {
    
   /// insert в таблицу `photos`. Принимает обязательные userId / url и опциональные albumId / description.
    func insertPhoto(
        userId: String,
        albumId: String?,
        url: URL,
        description: String? = nil
    ) async throws {
        var body: [String: Any] = [
            "user_id": userId,
            "url": url.absoluteString
        ]
        if let albumId {
            body["album_id"] = albumId
        }
        if let description {
            body["description"] = description
        }
        
        let data = try JSONSerialization.data(withJSONObject: [body], options: [])
        
        let request = client.makeRESTRequest(
            path: "photos",
            method: "POST",
            body: data
        )
        
        try await client.performVoid(request)
    }
}
