import Foundation

/// Центральный объект доменной логики авторизации. Делегат для экранов логина/регистрации.
final class LoginInspector: LoginDelegateProtocol {
    
    private let checkerService: CheckerServiceProtocol
    private let userService: UserServiceProtocol
    private let authService: AuthServiceProtocol
    private let userCache: CDUserCacheProtocol
    private let networkService: NetworkStatusServiceProtocol
    
    init(
        checkerService: CheckerServiceProtocol,
        userService: UserServiceProtocol,
        authService: AuthServiceProtocol,
        userCache: CDUserCacheProtocol,
        networkService: NetworkStatusServiceProtocol
    ) {
        self.checkerService = checkerService
        self.userService = userService
        self.authService = authService
        self.userCache = userCache
        self.networkService = networkService
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
            
            // Пользователь с таким email уже зарегистрирован
            if ns.domain == "Supabase",
               ns.code == 422,
               let body = ns.userInfo["body"] as? String,
               body.contains("user_already_exists") {
                
                // Пробуем выполнить вход с теми же учетными данными
                do {
                    _ = try await authService.signIn(email: data.email, password: data.password)
                } catch {
                    // Если не удалось войти — пробрасываем доменную ошибку о занятости email
                    throw AppError.authGeneric(message: NSLocalizedString("error_auth_email_already_exists", comment: "Адрес электронной почты уже зарегистрирован")
                    )
                }
            } else {
                // Любая другая ошибка Supabase
                throw error
            }
        }
        
        // На этом этапе: пользователь только что зарегистрирован ИЛИ  успешно вошёл в существующую учётную запись
        guard let userID = authService.userID else {
            throw AppError.authGeneric(message: NSLocalizedString("error_auth_no_user_id", comment: "Не удалось получить идентификатор пользователя")
            )
        }
        
        AppLogger.debug("AUTH signUp -> \(userID)")
        
        let fullName = Name(firstName: data.firstName, lastName: data.lastName)
        
        // Соборка доменной модели пользователя для слоя profiles
        let user = User(
            id: userID,
            nickname: nil,
            name: fullName,
            gender: data.gender,
            email: data.email,
            phone: data.phone,
            city: data.city,
            birthDate: data.birthDate,
            
        )
        
        // Обновить / создать профиль в таблице profiles
        try await userService.createProfile(for: user)
        AppLogger.debug("PROFILES: создан/обновлён для userID = \(userID)")
        
        // Кешируем в Core Data (ошибку кеша не считаем фатальной)
        do {
            try await userCache.save(user)
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
    
    /// Вход по номеру телефона после успешной проверки OTP. Поиск профиля пользователя по полю phone в таблице profiles.
    func loginByPhone(_ phone: String) async throws -> User {
        // Найти профиль по телефону
        let user = try await userService.fetchProfile(phone: phone)
        // Устанавить локальную "сессию" для этого userID
        authService.setLocalSession(userID: user.id)
        
        // Сохранить в кеш
        do {
            try await userCache.save(user)
        } catch {
            AppLogger.error("UserCache save error: \(error)")
            throw AppError.cacheSaveError
        }
        
        return user
    }

    /// Загрузка профиля текущего авторизованного пользователя.
    ///
    /// Если нет `userID` в `authService`, пользователь не авторизован, и бросаем ошибку `authGeneric`.
    /// - **Онлайн** (`networkService.isConnected == true`):
    ///   - пробуем получить свежий профиль из Supabase (`userService.fetchProfile(userID:)`);
    ///   - при сетевой ошибке пытаемся подставить кешированного пользователя;
    ///   - если кеша нет — пробросить исходную ошибку.
    /// - **Оффлайн**:
    ///   - пробуем загрузить пользователя из кеша;
    ///   - если в кеше ничего нет — ошибка `networkOffline`.
    func loadCurrentUserProfile() async throws -> User {
        guard let userID = authService.userID else {
            throw AppError.authGeneric(message: NSLocalizedString("error_auth_no_user_id", comment: "Cannot get user id")
            )
        }
        if networkService.isConnected {
            // ОНЛАЙН: всегда из Supabase
            do {
                let user = try await userService.fetchProfile(userID: userID)
                try? await userCache.save(user)
                
                return user
            } catch {
                // Если сеть упала пробуем показать кеш, чтобы пользователь хоть что‑то видел
                if let cached = try? await userCache.load(userID: userID) {
                    AppLogger.error("Network error, falling back to cached user: \(error)")
                    return cached
                } else {
                    // Ничего в кеше - пробросить ошибку
                    throw error
                }
            }
        } else {
            // ОФФЛАЙН: только локальный кеш
            if let cached = try? await userCache.load(userID: userID) {
                return cached
            } else {
                // Ни интернета, ни кеша — показываем доменную ошибку сети
                throw AppError.networkOffline
            }
        }
    }
}
