import UIKit

/// Координатор, отвечает за все экраны авторизации: старт, логин по email, логин по телефону, регистрация.
final class LoginCoordinator: Coordinator {
    
    var controller: UIViewController
    var children: [Coordinator]
    /// Ссылка на основной координатор приложения, создаётся после успешной авторизации.
    private var mainCoordinator: MainCoordinator?
    
    private let navController: UINavigationController
    private let loginInspector: LoginInspector
    
    enum Presentation {
       // стартовый экран авторизации
       case start
       // вход по email и паролю
       case loginCredentials
       // экран регистрации
       case signUp
       // вход по номеру телефона
       case phoneLogin
       // ввод кода при регистрации
       case phoneSignUpCode(data: SignUpData, verificationID: String)
    }
    
    init(factory: LoginFactory) {
        children = []
        loginInspector = factory.makeLoginInspector()
        
        navController = UINavigationController()
        controller = navController
    }
    
    func setup() {
        present(.start)
        controller = navController
    }
    
    func present(_ presentation: Presentation) {
        switch presentation {
        // Стартовый экран с выбором сценария ("Вход" / "Регистрация")
        case .start:
            let startVC = AuthStartViewController()
            startVC.coordinator = self
            navController.setViewControllers([startVC], animated: false)
            
        // Экран автоизации по email и паролю
        case .loginCredentials:
            let loginVC = LogInViewController(delegate: loginInspector)
            loginVC.coordinator = self
            navController.pushViewController(loginVC, animated: true)
            
        // Экран регистрации
        case .signUp:
            let vm = SignUpViewModel(delegate: loginInspector)
            // После успешной отправки кода переход на экран ввода кода (режим signUp)
            vm.onSMSCodeSent = { [weak self] data, verificationID in
                self?.present(
                    .phoneSignUpCode(data: data, verificationID: verificationID)
                )
            }
            let signUpVC = SignUpViewController(viewModel: vm)
            signUpVC.coordinator = self
            navController.pushViewController(signUpVC, animated: true)
            
        // Экран аторизации по номеру телефона
        case .phoneLogin:
            let vm = PhoneLoginViewModel(
                delegate: loginInspector,
                mode: .login,                  // режим: авторизация
                initialPhone: nil,
                initialVerificationID: nil,
                initialState: .enterPhone      // начинаем с ввода номера
            )
            // После успешного входа — переход в основной флоу
            vm.onSuccess = { [weak self] user in
                self?.didLogin(user: user)
            }
            let phoneVC = PhoneLoginViewController(viewModel: vm)
            phoneVC.coordinator = self
            navController.pushViewController(phoneVC, animated: true)
            
        // Экран ввода кода при регистрации
        case .phoneSignUpCode(let data, let verificationID):
            let vm = PhoneLoginViewModel(
                delegate: loginInspector,
                mode: .signUp(data),                    // режим: регистрация с указанными данными
                initialPhone: data.phone,               // подтягиваем телефон из формы регистрации
                initialVerificationID: verificationID,
                initialState: .enterCode                // сразу открываем состояние ввода кода
            )
            vm.onSuccess = {[weak self] user in
                self?.didLogin(user: user)
            }
            let codeVC = PhoneLoginViewController(viewModel: vm)
            codeVC.coordinator = self
            navController.pushViewController(codeVC, animated: true)
        }
    }
    
    /// Вернуться на корневой экран авторизации (старт).
    func popToRoot() {
        navController.popToRootViewController(animated: true)
    }
    
    /// Обработчик успешной авторизации. Создаёт основной координатор и подменяет rootViewController окна.
    func didLogin(user: User) {
        let mainCoordinator = MainCoordinator(user: user)
        self.mainCoordinator = mainCoordinator
        children = [mainCoordinator]
        
        // Находим главное окно и переключаем корневой контроллер на основной флоу.
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController = mainCoordinator.controller
            window.makeKeyAndVisible()
        }
    }
}
