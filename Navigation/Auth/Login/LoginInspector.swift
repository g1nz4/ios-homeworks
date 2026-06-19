import Foundation

/// Центральный объект доменной логики авторизации. Делегат для экранов логина/регистрации.
final class LoginInspector: LoginDelegateProtocol {
    
    private let checkerService: CheckerServiceProtocol
    private let userService: SupabaseUserService
    private let authService: SupabaseAuthService
    private let userCache: UserCacheStore
    
    init(
        checkerService: CheckerServiceProtocol = CheckerService(),
        userService: SupabaseUserService = SupabaseUserService(),
        authService: SupabaseAuthService = SupabaseAuthService.shared,
        userCache: UserCacheStore = UserCacheStore()
    ) {
        self.checkerService = checkerService
        self.userService = userService
        self.authService = authService
        self.userCache = userCache
    }
    
    /// Вход по email / паролю через Supabase Auth.
    func checkCredentials(email: String, password: String) async throws {
        try await checkerService.checkCredentials(email: email, password: password)
    }
    
    /// Регистрация по email (+ создание/обновление профиля в profiles).
    func signUp(_ data: SignUpData) async throws -> User {
        // Пытаемся зарегистрировать пользователя в Supabase Auth
        do {
            try await checkerService.signUp(email: data.email, password: data.password)
        } catch {
            let ns = error as NSError
            
            // Специальный случай: пользователь с таким email уже зарегистрирован
            if ns.domain == "Supabase",
               ns.code == 422,
               let body = ns.userInfo["body"] as? String,
               body.contains("user_already_exists") {
                
                // Пробуем выполнить вход с теми же учетными данными
                do {
                    _ = try await authService.signIn(email: data.email, password: data.password)
                } catch {
                    throw NSError(
                        domain: "Auth",
                        code: 422,
                        userInfo: [NSLocalizedDescriptionKey: "Пользователь с таким email уже зарегистрирован."]
                    )
                }
            } else {
                // Любая другая ошибка Supabase
                throw error
            }
        }
        
        // На этом этапе: пользователь только что зарегистрирован ИЛИ  успешно вошёл в существующую учётную запись
        guard let userID = authService.userID else {
            throw NSError(
                domain: "Auth",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Не удалось получить данные пользователя"]
            )
        }
        
        AppLogger.debug("AUTH signUp -> \(userID)")
        
        let fullName = Name(firstName: data.firstName, lastName: data.lastName)
        
        let user = User(
            id: userID,
            nickname: nil,
            name: fullName,
            email: data.email,
            phone: data.phone,
            city: data.city,
            birthDate: data.birthDate
        )
        
        // Обновить / создать профиль в таблице profiles
        try await userService.createProfile(for: user)
        AppLogger.debug("PROFILES: создан/обновлён для userID = \(userID)")
        
        // Кешируем в Core Data (ошибку кеша не считаем фатальной)
        do {
            try userCache.save(user)
        } catch {
            AppLogger.error("UserCache save error: \(error)")
        }
        
        return user
    }
    
    /// Отправка SMS‑кода (OTP) на номер телефона.
    func sendSMSCode(to phone: String) async throws -> String {
        try await checkerService.sendSMSCode(to: phone)
    }
    
    /// Проверка SMS‑кода (OTP).
    func verifySMSCode(verificationID: String, code: String) async throws {
        try await checkerService.verifySMSCode(verificationID: verificationID, code: code)
    }
    
    /// Вход по номеру телефона после успешной проверки OTP.
    /// Поиск профиля пользователя по полю phone в таблице profiles.
    func loginByPhone(_ phone: String) async throws -> User {
        let user = try await userService.fetchProfile(phone: phone)
        
        do {
            try userCache.save(user)
        } catch {
            AppLogger.error("UserCache save error (loginByPhone): \(error)")
        }
        
        return user
    }
    
    
    
    /// Загрузка профиля текущего авторизованного пользователя. Сначала пробует взять данные из кеша (Core Data), затем — из Supabase.
    func loadCurrentUserProfile() async throws -> User {
        guard let userID = authService.userID else {
            throw NSError(
                domain: "Auth",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Не удалось получить данные пользователя"]
            )
        }
        
        // Пробуем загрузить из Core Data
        if let cached = try? userCache.load(userID: userID) {
            return cached
        }
        
        // Если в кеше нет — загружаем из Supabase (REST)
        let user = try await userService.fetchProfile(userID: userID)
        
        // Сохраняем в кеш на будущее
        do {
            try userCache.save(user)
        } catch {
            AppLogger.error("UserCache save error: \(error)")
        }
        
        return user
    }
}
