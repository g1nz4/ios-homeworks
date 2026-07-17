import UIKit

extension UIColor {

    static func createColor(lightMode: UIColor, darkMode: UIColor) -> UIColor {
        guard #available(iOS 13.0, *) else {
            return lightMode
        }

        return UIColor { traitCollection -> UIColor in
            return traitCollection.userInterfaceStyle == .light ? lightMode : darkMode
        }
    }
    
    /// Цвет таббара
    static var appTabBarBackground: UIColor {
        createColor(
            lightMode: .white,
            darkMode: .black
        )
    }

    /// Общий фон экранов
    static var appBackground: UIColor {
        createColor(
            lightMode: .white,
            darkMode: UIColor(red: 18/255, green: 18/255, blue: 18/255, alpha: 1)
        )
    }
    
    /// Вторичный фон (поля, ячейки)
    static var appSecondaryBackground: UIColor {
        createColor(
            lightMode: UIColor(white: 0.95, alpha: 1),
            darkMode: UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1)
        )
    }

    /// Основной текст
    static var appPrimaryText: UIColor {
        createColor(lightMode: .black, darkMode: .white)
    }

    /// Вторичный текст (подписи, placeholder)
    static var appSecondaryText: UIColor {
        createColor(
            lightMode: UIColor(white: 0.45, alpha: 1),
            darkMode: UIColor(white: 0.6, alpha: 1)
        )
    }

    /// Разделители, бордеры
    static var appSeparator: UIColor {
        createColor(
            lightMode: UIColor(white: 0.85, alpha: 1),
            darkMode: UIColor(white: 0.25, alpha: 1)
        )
    }

    /// Акцент (ссылки, иконки, кнопки)
    static var appAccent: UIColor {
        createColor(
            lightMode: UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1),
            darkMode: UIColor(red: 10/255, green: 132/255, blue: 255/255, alpha: 1)
        )
    }

    /// Цвет текста на кнопках
    static var appButtonText: UIColor {
        createColor(lightMode: .white, darkMode: .white)
    }

    /// Фон текстфилдов
    static var appTextFieldBackground: UIColor {
        createColor(
            lightMode: UIColor(white: 0.95, alpha: 1),
            darkMode: UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1)
        )
    }
}
