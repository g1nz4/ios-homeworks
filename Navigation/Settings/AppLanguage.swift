import Foundation

/// Поддерживаемые языки приложения.
enum AppLanguage: String, CaseIterable {
    case ru
    case en

    var code: String { rawValue }

    var title: String {
        switch self {
        case .ru:
            return LocalizationManager.shared?.localized("language.russian") ?? "Русский"
        case .en:
            return LocalizationManager.shared?.localized("language.english") ?? "English"
        }
    }
}
