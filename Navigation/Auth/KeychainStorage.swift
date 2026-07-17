import KeychainAccess

/// Обёртка над Keychain для хранения небольших строковых значений (userID, accessToken и т.п.). Использует библиотеку KeychainAccess.
final class KeychainStorage {
    
    static let shared = KeychainStorage()
    private let keychain = Keychain(service: "com.vkdemo.keychain")
    
    private init() {}
    
    /// Сохранить строковое значение в Keychain по ключу.
    func set(_ value: String?, forKey key: String) {
        guard let value = value else {
            keychain[key] = nil
            return
        }
        keychain[key] = value
    }
    
    /// Прочитать строковое значение из Keychain по ключу.
    func get(_ key: String) -> String? {
        keychain[key]
    }
    
    /// Удалить значение из Keychain по ключу.
    func remove(_ key: String) {
        keychain[key] = nil
    }
}
