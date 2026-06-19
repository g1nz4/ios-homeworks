import Supabase
import Foundation
/// Модель пользователя, которую возвращает Supabase Auth (упрощённая).
struct SupabaseAuthUser: Decodable {
    let id: String
    let email: String?
}
/// Сервис для работы с Supabase Auth (email / пароль), использует официальный Supabase SDK + fallback на тестового пользователя в DEBUG.
final class SupabaseAuthService {
    /// Синглтон для удобного доступа по всему приложению.
    static let shared = SupabaseAuthService()
    
    /// Клиент Supabase SDK.
    private let client = SupabaseSDK.client
    
    /// Последний полученный access‑token.
    private(set) var accessToken: String?
    
    /// Текущий userID (uuid пользователя из Supabase).
    private(set) var userID: String?
    
    private init() {}
    
    /// Регистрация нового пользователя по email/паролю через Supabase Auth.
    @discardableResult
    func signUp(email: String, password: String) async throws -> SupabaseAuthUser {
        // Официальный вызов SDK
        let response = try await client.auth.signUp(
            email: email,
            password: password
        )
        
        // user в ответе обязателен
        let user = response.user
        
        self.accessToken = response.session?.accessToken
        self.userID = user.id.uuidString
        
        // Маппинг на упрощённую доменную модель
        return SupabaseAuthUser(id: user.id.uuidString, email: user.email)
    }
    
    /// Вход существующего пользователя по email/паролю через Supabase Auth.
    /// Сначала пытаемся выполнить реальный вход через SDK.
    /// Если в DEBUG и вход не удался (на время пока Supabase Auth падает)— пробуем fallback на тестового пользователя.
    @discardableResult
    func signIn(email: String, password: String) async throws -> SupabaseAuthUser {
        do {
            // Пробуем реальный вход через Supabase Auth
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            
            self.accessToken = session.accessToken
            self.userID = session.user.id.uuidString
            
            AppLogger.debug("AUTH signIn REAL OK, userID = \(self.userID ?? "nil")")
            
            return SupabaseAuthUser(
                id: session.user.id.uuidString,
                email: session.user.email
            )
        } catch {
            // Логируем реальную ошибку
            let ns = error as NSError
            
            AppLogger.error(
                """
                ===== AUTH signIn REAL FAILED =====
                Domain = \(ns.domain) code = \(ns.code)
                Localized = \(ns.localizedDescription)
                UserInfo = \(ns.userInfo)
                ===================================
                """
            )
            // В режиме DEBUG делаем fallback на локальную заглушку для тестового пользователя (на случай если Supabase Auth падает) В релизной сборке — пробрасываем оригинальную ошибку
            #if DEBUG
            return try loginTestUser(email: email, password: password)
            #else
            throw error
            #endif
        }
    }
    
    /// Локальный вход для одного тестового пользователя,
    /// используется только в DEBUG, когда Supabase Auth недоступен.
    private func loginTestUser(email: String, password: String) throws -> SupabaseAuthUser {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        // Тестовый пользователь (из Supabase)
        let testEmail = "developer@test.ru"
        let testPassword = "qwe123!"
        let testUserID = "fd128278-aa4a-4771-9067-ec507aea811c"

        guard trimmedEmail == testEmail, password == testPassword else {
            // Для других учеток — возвращается ошибка авторизации
            throw NSError(
                domain: "Auth",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Неверный email или пароль"]
            )
        }

        // Устанавливаем "локальную" сессию
        self.accessToken = "local-token"
        self.userID = testUserID

        AppLogger.debug("AUTH signIn (DEBUG): logged in as test user, id = \(testUserID)")

        return SupabaseAuthUser(id: testUserID, email: testEmail)
    }
}
