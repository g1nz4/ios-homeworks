import UIKit

/// Делегат для отслеживания нажатия Backspace в OTP-полях.
protocol OTPTextFieldDelegate: AnyObject {
    /// Вызывается, когда пользователь нажал Backspace в пустом поле, чтобы перейти к предыдущему полю ввода.
    func otpTextFieldDidDelete(_ textField: OTPTextField)
}

/// Текстовое поле для ввода одноразового кода (OTP), перехватывает Backspace, когда поле уже пустое.
final class OTPTextField: UITextField {
    
    /// Делегат, которому сообщаем о нажатии Backspace в пустом поле.
    weak var otpDelegate: OTPTextFieldDelegate?
    
    /// Переопределение поведения Backspace: запоминаем, было ли поле пустым ДО удаления, вызываем стандартную логику `super.deleteBackward()`, если поле было пустым, уведомляем делегата. Это позволяет узнать, что пользователь жмёт Backspace на пустом поле и переключить фокус на предыдущее поле OTP.
    override func deleteBackward() {
        let isEmptyBefore = text?.isEmpty ?? true
        
        super.deleteBackward()
        
        if isEmptyBefore {
            otpDelegate?.otpTextFieldDidDelete(self)
        }
    }
}
