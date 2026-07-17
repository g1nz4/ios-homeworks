import Foundation

/// Идентификатор секции экрана настроек.
enum SettingsSectionID: Int, CaseIterable {
    case notifications // Настройки уведомлений
    case permissions   // Настройки доступов (камера, фото)
    case appearance    // Тема приложения
    case language      // Язык приложения
    case navigation    // Навигация по приложению

    var title: String {
        switch self {
        case .notifications: 
            return "Уведомления"
        case .permissions:   
            return "Доступы"
        case .appearance:    
            return "Внешний вид"
        case .language:
            return "Язык приложения"
        case .navigation:
            return "Навигация"
        }
    }
}

/// Идентификатор строки настроек.
enum SettingsRowID: Hashable {
    case notifications
    case camera
    case photos
    case theme
    case language
    case tabSwipe  
}

/// Модель данных для одной строки настроек.
struct SettingsRowViewData {
    let id: SettingsRowID
    let title: String
    let detail: String?
    let isSwitch: Bool
    let isOn: Bool
    let showsDisclosure: Bool
}

/// Модель данных для футера секции настроек.
struct SettingsFooterViewData: Equatable {
    let text: String
    let showsButton: Bool
    let buttonTitle: String?
}

/// Модель данных для одной секции настроек.
struct SettingsSectionViewData {
    let id: SettingsSectionID
    let title: String
    let rows: [SettingsRowViewData]
    let footer: SettingsFooterViewData?
}

/// Тип системного разрешения, с которым работает экран настроек.
enum PermissionKind {
    case notifications
    case camera
    case photos
}
