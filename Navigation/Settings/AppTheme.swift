import Foundation

/// Тема оформления приложения.
enum AppTheme: Int, CaseIterable {
    case system = 0
    case light = 1
    case dark = 2

    var title: String {
        switch self {
        case .system: 
            return "Системная"
        case .light:  
            return "Светлая"
        case .dark:
            return "Тёмная"
        }
    }
}
