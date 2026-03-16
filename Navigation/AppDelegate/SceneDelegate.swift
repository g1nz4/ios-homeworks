import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var mainCoordinator: MainCoordinator?
    private var appConfiguration: AppConfiguration?
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let scene = (scene as? UIWindowScene) else { return }
        
        let peopleURL = URL(string: "https://swapi.dev/api/people/25")!
        let starshipURL = URL(string: "https://swapi.dev/api/starships/13")!
        let planetURL = URL(string: "https://swapi.dev/api/planets/6")!
        
        let config: [AppConfiguration] = [
            .people(peopleURL),
            .starship(starshipURL),
            .planet(planetURL)
        ]
        appConfiguration = config.randomElement()!
        
        NetworkService.request(for: appConfiguration!) { result in
            switch result {
            case .success(let data):
                print("SUCCESS :)\n", data)
                
            case .failure(let error):
                print("FAILURE :(\n", error)
            }
        }
           
        let window = UIWindow(windowScene: scene)
        
        let logInViewController = LogInViewController()
        let loginFactory = MyLoginFactory()
        logInViewController.loginDelegate = loginFactory.makeLoginInspector()
        let loginNavigationController = UINavigationController(rootViewController: logInViewController)
        logInViewController.loginSuccess = { [weak self] user in
            guard let self = self else { return }
            
            let mainCoordinator = MainCoordinator(user: user)
            self.mainCoordinator = mainCoordinator
            self.window?.rootViewController = mainCoordinator.controller
        }
   
        window.rootViewController = loginNavigationController
        window.makeKeyAndVisible()
                
        self.window = window
    }
}

