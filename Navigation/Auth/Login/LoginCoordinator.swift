import UIKit

final class LoginCoordinator: Coordinator {
    
    var controller: UIViewController
    var children: [Coordinator]
    
    private weak var notificationsService: LocalNotificationsServiceProtocol?
    private var mainCoordinator: MainCoordinator?
    
    private let loginVC: LogInViewController
    private let loginNC: UINavigationController
    private let loginInspector: LoginInspector
    
    enum Presentation {
        case signUp
    }
    
    init(notificationsService: LocalNotificationsServiceProtocol?) {
        self.notificationsService = notificationsService
        
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
        let mainCoordinator = MainCoordinator(
            user: user,
            notificationsService: notificationsService
        )
        self.mainCoordinator = mainCoordinator
        children = [mainCoordinator]

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController = mainCoordinator.controller
            window.makeKeyAndVisible()
        }
        
        notificationsService?.registerForLatestUpdatesIfPossible()
    }
}
