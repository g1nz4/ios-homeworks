import Foundation

/// Общий тип ошибок доменного уровня приложения.
enum AppError: Error {
  
    // MARK: - Auth
    
    /// Неверный логин или пароль.
    case authWrongCredentials
    /// Прочие ошибки авторизации с произвольным сообщением.
    case authGeneric(message: String)
    
    // MARK: - OTP
    
    /// Код подтверждения не найден.
    case otpNotFound
    /// Неверный код подтверждения.
    case otpInvalid
    /// Срок действия кода истёк.
    case otpExpired
    /// Не удалось разобрать дату из токена / ответа.
    case otpInvalidDate
    
    // MARK: - Профиль / Supabase REST
    
    /// Профиль пользователя не найден.
    case profileNotFound
    /// Ошибка, вернувшаяся от REST‑API Supabase.
    case supabase(status: Int, message: String)
    
    // MARK: - Низкоуровневые
    
    /// Сетевые ошибки URLSession или нижележащих слоёв.
    case network(underlying: Error)
    /// Ошибка декодинга JSON / данных.
    case decoding(underlying: Error)
    /// Любая другая нераспознанная ошибка.
    case unknown(message: String)
    
    // MARK: - Кеш
    
    /// Не удалось сохранить данные в кеш.
    case cacheSaveError
    /// Общая ошибка кеша с сообщением.
    case cache(message: String)
    
    // MARK: - Валидация
    
    /// Некорректный формат телефона.
    case errorPhoneInvalid
    /// Отсутствует verificationID при работе с OTP.
    case errorOtpNoVerificationID
    /// Неверный код OTP, предлагается повторить попытку.
    case errorOtpWrongCodeRetry
    /// Пустой логин или пароль.
    case emptyCredentials
    /// Неверный логин или пароль (для UX‑сообщения).
    case invalidCredentials
    /// Пароль слишком короткий.
    case weakPassword
    /// Некорректный формат email.
    case invalidEmail
    /// Пароли не совпадают.
    case passwordsDoNotMatch
    
    // MARK: - Разное из App
    
    /// Не удалось загрузить ленту.
    case feedLoadingFailed
    /// Не удалось обновить ленту.
    case feedUpdateFailed
    /// Не удалось загрузить профиль.
    case profileLoadingFailed
    /// Не удалось обновить статус.
    case statusUpdateFailed
    /// Файл не найден.
    case fileNotFound
    /// Ошибка при работе с AVAudioPlayer.
    case errorAVAudioPlayer
    /// Ошибка сохранения избранного.
    case favoritesSavingFailed
    /// Ошибка загрузки избранного.
    case favoritesLoadingFailed
    
    // MARK: - Network
    
    /// Нет интернет‑соединения.
    case networkOffline
}

/// Локализованные сообщения для пользователя.
extension AppError: LocalizedError {
    var errorDescription: String? {
        switch self {
        // MARK: Auth
            
        case .authWrongCredentials:
            return NSLocalizedString("error_auth_wrong_credentials", comment: "Неверный email или пароль")
            
        case .authGeneric(let message):
            return message.isEmpty ? NSLocalizedString("error_auth_generic", comment: "Ошибка авторизации") : message
            
        // MARK: OTP
            
        case .otpNotFound:
            return NSLocalizedString("error_otp_not_found", comment: "Код подтверждения не найден")
        
        case .otpInvalid:
            return NSLocalizedString("error_otp_invalid", comment: "Неверный код подтверждения")
       
        case .otpExpired:
            return NSLocalizedString("error_otp_expired", comment: "Срок действия кода подтверждения истёк"
            )
        
        case .otpInvalidDate:
            return NSLocalizedString("error_otp_date_format", comment: "Ошибка разбора даты в OTP")
            
        // MARK: Профили / Supabase
            
        case .profileNotFound:
            return NSLocalizedString("error_profile_not_found", comment: "Профиль пользователя не найден")
            
        case .supabase(_, let message):
            return message.isEmpty ? NSLocalizedString("error_server_generic", comment: "Ошибка сервера") : message
            
        // MARK: Низкоуровневые
            
        case .network:
            return NSLocalizedString("error_network", comment: "Сетевая ошибка")
       
        case .decoding:
            return NSLocalizedString("error_decoding", comment: "Ошибка обработки данных")
       
        case .unknown(let message):
            return message.isEmpty ? NSLocalizedString("error_unknown", comment: "Неизвестная ошибка") : message
            
        // MARK: Кеш
            
        case .cacheSaveError:
            return NSLocalizedString("cache_save_error", comment: "Не удалось сохранить данные в кеш")
       
        case .cache(let message):
            return message.isEmpty ? NSLocalizedString("error_cache_generic", comment: "Ошибка кеша") : message
            
        // MARK: Валидация / навигация (телефон / OTP)
            
        case .errorPhoneInvalid:
            return NSLocalizedString("error_phone_invalid", comment: "Неверный формат телефона")
       
        case .errorOtpNoVerificationID:
            return NSLocalizedString("error_otp_no_verification_id", comment: "Отсутствует идентификатор подтверждения")
       
        case .errorOtpWrongCodeRetry:
            return NSLocalizedString("error_otp_wrong_code_retry", comment: "Неверный код, попробуйте ещё раз")
            
        // MARK: Поля логина/регистрации
            
        case .emptyCredentials:
            return NSLocalizedString("error_empty_credentials", comment: "Не заполнены логин или пароль")
       
        case .invalidCredentials:
            return NSLocalizedString("error_invalid_credentials", comment: "Неверный логин или пароль")
       
        case .weakPassword:
            return NSLocalizedString("error_weak_password", comment: "Слишком простой пароль")
       
        case .invalidEmail:
            return NSLocalizedString("error_invalid_email", comment: "Некорректный email")
        
        case .passwordsDoNotMatch:
            return NSLocalizedString("error_passwords_do_not_match", comment: "Введённые пароли не совпадают")
            
        // MARK: Остальные (из NavigationError)
            
        case .feedLoadingFailed:
            return NSLocalizedString("error_feed_loading_failed", comment: "Не удалось загрузить ленту")
       
        case .feedUpdateFailed:
            return NSLocalizedString("error_feed_update_failed", comment: "Не удалось обновить ленту")
       
        case .profileLoadingFailed:
            return NSLocalizedString("error_profile_loading_failed", comment: "Не удалось загрузить профиль")
        
        case .statusUpdateFailed:
            return NSLocalizedString("error_status_update_failed", comment: "Не удалось обновить статус")
       
        case .fileNotFound:
            return NSLocalizedString("error_file_not_found", comment: "Файл не найден")
        
        case .errorAVAudioPlayer:
            return NSLocalizedString("error_av_audio_player", comment: "Ошибка аудио‑плеера")
        
        case .favoritesSavingFailed:
            return NSLocalizedString("error_favorites_saving_failed", comment: "Не удалось сохранить избранное")
        
        case .favoritesLoadingFailed:
            return NSLocalizedString("error_favorites_loading_failed", comment: "Не удалось загрузить избранное")
            
        // MARK: - Network
            
        case .networkOffline:
            return NSLocalizedString("error_network_offline", comment: "Нет подключения к интернету")
        }
    }
}
