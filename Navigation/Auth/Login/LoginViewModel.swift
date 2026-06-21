import Foundation

/// ViewModel экрана входа по email / паролю.
@MainActor
final class LoginViewModel {
    // Делегат, который ходит в реальный слой логики (LoginInspector / сервисы...)
    private weak var delegate: LoginDelegateProtocol?
    
    var email: String = ""
    var password: String = ""
    
    /// Флаг загрузки (используется для кнопки и блокировки UI).
    let isLoading: Observable<Bool> = Observable(false)
    /// Текст ошибки для показа алерта.
    let errorText: Observable<String?> = Observable(nil)
    /// Коллбэк об успешном входе: отдаём наверх доменную модель пользователя.
    var onSuccess: ((User) -> Void)?
    
    init(delegate: LoginDelegateProtocol){
        self.delegate = delegate
    }
    
    /// Запускает сценарий входа по email / паролю.
    func login() async {
        guard let delegate = delegate else { return }
        
        // Убираем пробелы/переводы строк с краёв email
        let emailTrimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Базовая проверка: поля не пустые
        guard !emailTrimmed.isEmpty, !password.isEmpty else {
            errorText.value = AppError.invalidCredentials.localizedDescription
            return
        }
        // Валидация формата email
        guard emailTrimmed.contains("@"), emailTrimmed.contains(".") else {
            errorText.value = AppError.invalidEmail.localizedDescription
            return
        }
        // Проверка длины пароля (минимум 6 символов)
        guard password.count >= 6 else {
            errorText.value = AppError.weakPassword.localizedDescription
            return
        }
        
        isLoading.value = true
        errorText.value = nil
        defer { isLoading.value = false }
        
        do {
            // Проверка credentials через Supabase Auth
            try await delegate.checkCredentials(email: emailTrimmed, password: password)
            
            // Загрузка профиля пользователя
            let user = try await delegate.loadCurrentUserProfile()
            
            // Сообщаем координатору/контроллеру об успешном входе
            onSuccess?(user)
        } catch {
            errorText.value = error.localizedDescription
        }
    }
}
