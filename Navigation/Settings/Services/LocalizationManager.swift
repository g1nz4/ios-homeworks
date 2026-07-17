import Foundation

/// Синглтон, отвечающий за выбор языка .  Хранит текущий язык, синхронизирует его с UserSettingsStorage .
final class LocalizationManager {

    /// Глобальный экземпляр. Инициализируется через `configure(storage:)`.
    static private(set) var shared: LocalizationManager!

    /// Конфигурирование менеджера. Parameter storage: объект, который хранит настройки пользователя.
    static func configure(storage: UserSettingsStorage) {
        shared = LocalizationManager(settingsStorage: storage)
    }

    /// Хранилище настроек, в котором лежит выбранный язык.
    private let settingsStorage: UserSettingsStorage

    /// Текущий язык приложения.  При изменении отправляется нотификация `.appLanguageDidChange`.
    private(set) var currentLanguage: AppLanguage {
        didSet {
            NotificationCenter.default.post(
                name: .appLanguageDidChange,
                object: nil
            )
        }
    }

    /// Приватный инициализатор — создается только через `configure(storage:)`.
    private init(settingsStorage: UserSettingsStorage) {
        self.settingsStorage = settingsStorage
        self.currentLanguage = settingsStorage.appLanguage
    }

    /// Устанавливает новый язык приложения.
    func setLanguage(_ language: AppLanguage) {
        guard language != currentLanguage else { return }

        currentLanguage = language
        settingsStorage.appLanguage = language
    }

    /// Возвращает локализованную строку по ключу.
    func localized(_ key: String, table: String? = nil) -> String {
        NSLocalizedString(
            key,
            tableName: table,
            bundle: bundle,
            value: "",
            comment: ""
        )
    }

    /// Bundle для текущего языка. Если нужный не найден, используется основной bundle.
    private var bundle: Bundle {
        guard
            let path = Bundle.main.path(forResource: currentLanguage.code, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return .main
        }
        return bundle
    }
}


