import Foundation

/// Простой логгер приложения чтобы выодить сообщения ТОЛЬКО в DEBUG-сборке.
enum AppLogger {
    
    /// Логирование отладочной информации.
    static func debug(_ message: String) {
        #if DEBUG
        print("[DEBUG] \(message)")
        #endif
    }

    /// Логирование ошибок.
    static func error(_ message: String) {
        #if DEBUG
        print("[ERROR] \(message)")
        #endif
    }
}
