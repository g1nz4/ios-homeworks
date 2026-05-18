import UIKit

final class LoginCoordinator: Coordinator {
    
    var controller: UIViewController
    var children: [Coordinator]
    
    private var mainCoordinator: MainCoordinator?
    
    private let loginVC: LogInViewController
    private let loginNC: UINavigationController
    private let loginInspector: LoginInspector
    
    enum Presentation {
        case signUp
    }
    
    init() {
        children = []
        loginInspector = LoginInspector()
        
        loginVC = LogInViewController(delegate: loginInspector)
        loginNC = UINavigationController(rootViewController: loginVC)
        controller = loginNC
        
        setup()
    }
    
    func setup() {
        loginVC.coordinator = self
    }
    
    func present(_ presentation: Presentation) {
        switch presentation {
        case .signUp:
            let signUpVC = SignUpViewController(delegate: loginInspector)
            signUpVC.coordinator = self
            loginNC.pushViewController(signUpVC, animated: true)
        }
    }
    
    func popToRoot() {
        loginNC.popToRootViewController(animated: true)
    }
    
    func didLogin(user: User) {
        let mainCoordinator = MainCoordinator(user: user)
        self.mainCoordinator = mainCoordinator
        children = [mainCoordinator]

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController = mainCoordinator.controller
            window.makeKeyAndVisible()
        }
    }
}
