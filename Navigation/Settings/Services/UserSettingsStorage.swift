import Foundation

/// Хранилище пользовательских настроек приложения поверх `UserDefaults`.
///
/// Отвечает за:
/// 1.  язык приложения;
/// 2. тему приложения;
/// 3. флаги разрешений (уведомления, камера, фото);
/// 4.  доп. настройки UI (свайп между вкладками таббара).
final class UserSettingsStorage {

    /// Внутренние ключи для `UserDefaults`.
    private enum Keys {
        static let notificationsEnabled = "settings.notificationsEnabled"
        static let cameraEnabled = "settings.cameraEnabled"
        static let photosEnabled = "settings.photosEnabled"
        static let appTheme = "settings.appTheme"
        static let appLanguage = "appLanguage"
        static let tabSwipeEnabled = "settings.tabSwipeEnabled"
    }

    /// Используемый экземпляр `UserDefaults`.
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Выбранный язык приложения.  Если значение ещё не сохранено, по умолчанию используется `.ru`.
    var appLanguage: AppLanguage {
        get {
            if let raw = defaults.string(forKey: Keys.appLanguage),
               let lang = AppLanguage(rawValue: raw) {
                return lang
            }
            return .ru
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.appLanguage)
        }
    }

    /// Разрешён ли свайп между вкладками таббара. По умолчанию включен, если ключ ещё не записывали.
    var tabSwipeEnabled: Bool {
        get {
            // Если значения ещё нет — свайп включён
            if defaults.object(forKey: Keys.tabSwipeEnabled) == nil {
                return true
            }
            return defaults.bool(forKey: Keys.tabSwipeEnabled)
        }
        set {
            defaults.set(newValue, forKey: Keys.tabSwipeEnabled)
        }
    }
    
    /// Флаг, включены ли уведомления (хранит свой, отдельно от системного статуса).
    var notificationsEnabled: Bool {
        get { defaults.bool(forKey: Keys.notificationsEnabled) }
        set { defaults.set(newValue, forKey: Keys.notificationsEnabled) }
    }

    /// Флаг, включена ли камера (если пользователь уже соглашался внутри приложения).
    var cameraEnabled: Bool {
        get { defaults.bool(forKey: Keys.cameraEnabled) }
        set { defaults.set(newValue, forKey: Keys.cameraEnabled) }
    }

    /// Флаг, включён ли доступ к фото (аналогично `cameraEnabled`).
    var photosEnabled: Bool {
        get { defaults.bool(forKey: Keys.photosEnabled) }
        set { defaults.set(newValue, forKey: Keys.photosEnabled) }
    }

    /// Выбранная тема приложения.  Если сохранённого значения нет или оно некорректно — возвращает `.system`.
    var appTheme: AppTheme {
        get {
            let raw = defaults.integer(forKey: Keys.appTheme)
            return AppTheme(rawValue: raw) ?? .system
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.appTheme)
        }
    }
}
