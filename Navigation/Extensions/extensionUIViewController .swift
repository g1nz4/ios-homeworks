import UIKit

/// Общий хелпер для показа простых алертов по всему приложению.
extension UIViewController {
    
    static let defaultTitle = NSLocalizedString("alert_default_title", comment: "Аlert default title")
    
    /// Показывает простой алерт с заголовком, сообщением и одной кнопкой "ОК".
    func showAlert(
        title: String = defaultTitle,
        message: String,
        buttonTitle: String = "OK")
    {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: buttonTitle, style: .default))
        present(alert, animated: true)
    }
}
