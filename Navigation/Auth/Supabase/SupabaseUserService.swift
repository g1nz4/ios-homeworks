import Foundation

/// Протокол сервиса работы с профилями пользователей (для тестов).
protocol UserServiceProtocol: AnyObject {
    func createProfile(for user: User) async throws
    func fetchProfile(userID: String) async throws -> User
    func fetchProfile(phone: String) async throws -> User
}

/// Сервис для работы с таблицей profiles в Supabase.
final class SupabaseUserService: UserServiceProtocol {
    
    private let client = SupabaseRESTClient()
    private let cacheStore = UserCacheStore()
    
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
            try cacheStore.save(user)
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
            try cacheStore.save(user)
        } catch {
            AppLogger.debug("UserCache save error: \(error)")
        }
        
        return user
    }
}
