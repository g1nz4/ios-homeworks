import Foundation

protocol LoginViewModelProtocol {
    var email: String { get set }
    var password: String { get set }
    
    var isLoading: Observable<Bool> { get }
    var errorText: Observable<String?> { get }
    
    var onSuccess: ((User) -> Void)? { get set }
    
    func login()
}

final class LoginViewModel: LoginViewModelProtocol {
    
    private weak var loginDelegate: LogInViewControllerDelegate?
    
    var email: String = ""
    var password: String = ""
    
    let isLoading: Observable<Bool> = Observable(false)
    let errorText: Observable<String?> = Observable(nil)
    
    var onSuccess: ((User) -> Void)?
    
    init(loginDelegate: LogInViewControllerDelegate){
        self.loginDelegate = loginDelegate
    }
    
    func login() {
        guard !email.isEmpty, !password.isEmpty else {
            errorText.value = NavigationError.emptyCredentials.rawValue
            return
        }
        
        guard email.contains("@"), email.contains(".") else {
            errorText.value = NavigationError.invalidEmail.rawValue
            return
        }
        
        guard password.count >= 6 else {
            errorText.value = NavigationError.weakPassword.rawValue
            return
        }
        
        isLoading.value = true
        errorText.value = nil
        
        loginDelegate?.checkCredentials(
            email: email,
            password: password
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                
                self.isLoading.value = false
                
                switch result {
                case .success:
                    let user = TestUserService().user
                    self.onSuccess?(user)
                case .failure:
                    self.errorText.value = NavigationError.invalidCredentials.rawValue
                }
            }
        }
    }
}
