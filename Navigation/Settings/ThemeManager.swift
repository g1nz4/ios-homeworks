import UIKit

/// Менеджер темы приложения.
/// Отвечает только за применение выбранной темы к `UIWindow`.
/// Хранение текущей темы и её выбор происходят  в `UserSettingsStorage` / `SettingsViewModel`.
final class ThemeManager {

    static let shared = ThemeManager()

    private init() {}

    func apply(theme: AppTheme, to window: UIWindow) {
        switch theme {
        case .light:
            window.overrideUserInterfaceStyle = .light
        case .dark:
            window.overrideUserInterfaceStyle = .dark
        case .system:
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
}
