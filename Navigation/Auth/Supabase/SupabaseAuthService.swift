import Supabase
import Foundation

/// Протокол сервиса авторизации (чтобы подменять реализацию в тестах).
protocol AuthServiceProtocol: AnyObject {
    /// Текущий идентификатор пользователя (uuid из Supabase), nil — пользователь не авторизован.
    var userID: String? { get }
    /// Выход из аккаунта (очистка сессии и локального состояния).
    func logout() async throws
    /// Вход по email/паролю через Supabase Auth.
    @discardableResult
    func signIn(email: String, password: String) async throws -> SupabaseAuthUser
    /// Регистрация по email/паролю через Supabase Auth.
    @discardableResult
    func signUp(email: String, password: String) async throws -> SupabaseAuthUser
    
    /// Устанавливает локальную «сессию» без реального логина через Supabase Auth.
    /// Используется для входа по телефону после успешного OTP: присваивает userID, сохраняет данные в Keychain,  даёт приложению понять, что есть авторизованный пользователь.
    func setLocalSession(userID: String)
}

/// Модель пользователя, которую возвращает Supabase Auth (упрощённая).
struct SupabaseAuthUser: Decodable {
    let id: String
    let email: String?
}

/// Сервис для работы с Supabase Auth (email / пароль), использует официальный Supabase SDK + fallback на тестового пользователя в DEBUG.
final class SupabaseAuthService: AuthServiceProtocol {
    /// Синглтон для удобного доступа по всему приложению.
    static let shared = SupabaseAuthService()
    
    /// Клиент Supabase SDK.
    private let client = SupabaseSDK.client
    
    /// Последний полученный access‑token.
    private(set) var accessToken: String?
    
    /// Текущий userID (uuid пользователя из Supabase).
    private(set) var userID: String?
    /// Хранилище данных (userID, accessToken).
    private let keychain = KeychainStorage.shared
    /// Ключ для userID в Keychain.
    private let userIDKey = "auth.userID"
    /// Ключ для accessToken в Keychain.
    private let accessTokenKey = "auth.accessToken"
    
    private init() {
        // Пытаемся восстановить сохранённую сессию из Keychain
        self.accessToken = keychain.get(accessTokenKey)
        self.userID = keychain.get(userIDKey)
        
        AppLogger.debug("SupabaseAuthService init: restored userID = \(self.userID ?? "nil")")
    }
    
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
        
        // Сохраняем токен и идентификатор пользователя из сессии
        self.accessToken = response.session?.accessToken
        self.userID = user.id.uuidString
        
        // Пишем данные в Keychain, чтобы восстановить сессию при следующем запуске приложения
        keychain.set(self.userID, forKey: userIDKey)
        keychain.set(self.accessToken, forKey: accessTokenKey)
        
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
            
            keychain.set(self.userID, forKey: userIDKey)
            keychain.set(self.accessToken, forKey: accessTokenKey)
            
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
            throw mapAuthError(ns)
            #endif
        }
    }
    
    /// Выход из аккаунта:  вызываем signOut у Supabase и очищаем локальные поля и Keychain.
    func logout() async throws {
        // Выход из Supabase
        try await client.auth.signOut()
        
        // Оистка локального состояния
        self.accessToken = nil
        self.userID = nil
        
        keychain.remove(userIDKey)
        keychain.remove(accessTokenKey)
        
        AppLogger.debug("AUTH logout: cleared userID and accessToken from Keychain")
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
            throw AppError.authWrongCredentials
        }

        // Устанавливаем "локальную" сессию
        self.accessToken = "local-token"
        self.userID = testUserID
        
        keychain.set(self.userID, forKey: userIDKey)
        keychain.set(self.accessToken, forKey: accessTokenKey)

        AppLogger.debug("AUTH signIn (DEBUG): test user, id = \(testUserID)")

        return SupabaseAuthUser(id: testUserID, email: testEmail)
    }
    
    /// Устанавливает локальную сессию для пользовательского `userID`,
    /// не обращаясь к Supabase Auth.
    ///
    /// Используется при авторизации по телефону:  после успешного OTP находим профиль по номеру, берём у профиля `user.id`,  вызываем `setLocalSession(userID:)`, чтобы: `AppCoordinator` увидел авторизованного пользователя, и `LoginInspector.loadCurrentUserProfile()` работал как обычно.
    func setLocalSession(userID: String) {
        self.userID = userID
        self.accessToken = "phone-login-local-token"

        keychain.set(self.userID, forKey: userIDKey)
        keychain.set(self.accessToken, forKey: accessTokenKey)

        AppLogger.debug("AUTH setLocalSession: userID = \(userID)")
    }
    
    /// Маппинг ошибок Supabase Auth в доменные AppError для UI (400/401/403: неверный логин или пароль, остальное:  общая ошибка авторизации).
    private func mapAuthError(_ error: NSError) -> AppError {
        switch error.code {
        case 400, 401, 403:
            return .authWrongCredentials
        default:
            return .authGeneric(message: error.localizedDescription)
        }
    }
}
