import Foundation

protocol SignUpViewModelProtocol {
    var email: String { get set }
    var password: String { get set }
    var repeatPassword: String { get set }
    
    var errorText: Observable<String?> { get }
    var onSuccess: (() -> Void)? { get set }
    
    func signUp()
}

final class SignUpViewModel: SignUpViewModelProtocol {
    
    private weak var signUpDelegate: LogInViewControllerDelegate?
    
    var email: String = ""
    var password: String = ""
    var repeatPassword: String = ""
    
    let errorText = Observable<String?>(nil)

    var onSuccess: (() -> Void)?
    
    init(signUpDelegate: LogInViewControllerDelegate) {
        self.signUpDelegate = signUpDelegate
    }
    
    func signUp() {
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
        
        errorText.value = nil
        
        signUpDelegate?.signUp(
            email: email,
            password: password
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                
                switch result {
                case .success:
                    self.onSuccess?()
                case .failure(let error):
                    self.errorText.value = error.localizedDescription
                }
            }
        }
    }
}
