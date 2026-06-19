import Foundation

struct SignUpData {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let city: String
    let phone: String
    let birthDate: Date
}

/// Данные регистрации, которые будут сохранены/отправлены после подтверждения телефона.
@MainActor
final class SignUpViewModel {
    
    private weak var delegate: LoginDelegateProtocol?
    
    // Входные поля формы
    var email: String = ""
    var password: String = ""
    var repeatPassword: String = ""
    var firstName: String = ""
    var lastName: String = ""
    /// Телефон в формате +7XXXXXXXXXX, заполняется из маски в контроллере.
    var phone: String = ""
    var city: String = ""
    var birthDate: Date = Date()
    
    /// Признак валидного номера телефона для регистрации. Ожидаемый формат +7XXXXXXXXXX (12 символов).
    var isPhoneValid: Bool {
      phone.hasPrefix("+7") && phone.count == 12
    }
    
    let isLoading = Observable<Bool>(false)
    let errorText = Observable<String?>(nil)
    
    /// Колбэк, вызывается после успешной отправки SMS-кода. Передаёт собранные данные и verificationID.
    var onSMSCodeSent: ((SignUpData, String) -> Void)?
    
    init(delegate: LoginDelegateProtocol) {
        self.delegate = delegate
    }
    
    /// Старт процесса регистрации: локальная валидация полей - > отправка SMS-кода на телефон  - > переход к экрану ввода кода.
    func signUp() {
        Task { [weak self] in
            guard let self, let delegate = self.delegate else { return }
            
            // Базовая валидация полей
            guard !email.isEmpty,
                  !password.isEmpty,
                  !repeatPassword.isEmpty else {
                errorText.value = NavigationError.emptyCredentials.rawValue
                return
            }
            
            guard email.contains("@"), email.contains(".") else {
                errorText.value = NavigationError.invalidEmail.rawValue
                return
            }
            
            guard password.count >= 6 && repeatPassword.count >= 6 else {
                errorText.value = NavigationError.weakPassword.rawValue
                return
            }
            
            guard password == repeatPassword else {
                errorText.value = NavigationError.passwordsDoNotMatch.rawValue
                return
            }
            
            guard isPhoneValid else {
                errorText.value = "Введите корректный номер телефона"
                return
            }
            
            errorText.value = nil
            isLoading.value = true
            defer { isLoading.value = false }
            
            do {
                let data = SignUpData(
                    email: email,
                    password: password,
                    firstName: firstName,
                    lastName: lastName,
                    city: city,
                    phone: phone,
                    birthDate: birthDate
                )
                // Отправить код на указанный номер
                let verificationID = try await delegate.sendSMSCode(to: phone)
                onSMSCodeSent?(data, verificationID)
            } catch {
                errorText.value = error.localizedDescription
            }
        }
        
    }
}
