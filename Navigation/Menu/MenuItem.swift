import UIKit
import Foundation

/// Перечисление всех пунктов меню профиля
enum MenuItem: CaseIterable {
    case friends
    case photos
    case music
    case favorites
    case storiesArchive
    case settings
    case logout

    /// Текстовая подпись под иконкой
    var title: String {
        switch self {
        case .friends: return "Друзья"
        case .photos: return "Фото"
        case .music: return "Музыка"
        case .favorites: return "Избранное"
        case .storiesArchive: return "Архив историй"
        case .settings: return "Настройки"
        case .logout: return "Выход из профиля"
        }
    }

    /// Название SF Symbol для иконки
    var systemImageName: String {
        switch self {
        case .friends: return "person.2.fill"
        case .photos: return "photo.on.rectangle"
        case .music: return "music.note.list"
        case .favorites: return "star.fill"
        case .storiesArchive: return "clock.arrow.circlepath"
        case .settings: return "gearshape.fill"
        case .logout: return "rectangle.portrait.and.arrow.right"
        }
    }

    /// Цвет фона иконки/тайла 
    var color: UIColor {
        switch self {
        case .friends:
            return UIColor(red: 0.00, green: 0.78, blue: 0.40, alpha: 1.0) // зелёный 
        case .photos:
            return UIColor(red: 0.15, green: 0.57, blue: 1.00, alpha: 1.0) // синий
        case .music:
            return UIColor(red: 0.61, green: 0.31, blue: 1.00, alpha: 1.0) // фиолетовый
        case .favorites:
            return UIColor(red: 1.00, green: 0.40, blue: 0.27, alpha: 1.0) // оранжево-красный
        case .storiesArchive:
            return UIColor(red: 1.00, green: 0.72, blue: 0.13, alpha: 1.0) // жёлтый
        case .settings:
            return UIColor(red: 0.56, green: 0.58, blue: 0.64, alpha: 1.0) // серый
        case .logout:
            return UIColor(red: 0.96, green: 0.30, blue: 0.39, alpha: 1.0) // красный
        }
    }
}
