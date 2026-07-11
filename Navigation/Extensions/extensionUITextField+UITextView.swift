import UIKit

/// Добавляет над клавиатурой тулбар с кнопкой "Готово"
extension UITextField {
    func addDoneButton(target: Any?, action: Selector) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                   target: nil,
                                   action: nil)
       
        let done = UIBarButtonItem(title: "Готово",
                                   style: .done,
                                   target: target,
                                   action: action)
        toolbar.items = [flex, done]
        
        inputAccessoryView = toolbar
    }
}

extension UITextView {
    /// Добавляет над клавиатурой тулбар с кнопкой "Готово"
    func addDoneButton(target: Any?, action: Selector) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                   target: nil,
                                   action: nil)
        let done = UIBarButtonItem(title: "Готово",
                                   style: .done,
                                   target: target,
                                   action: action)
        toolbar.items = [flex, done]
        
        inputAccessoryView = toolbar
    }
}
