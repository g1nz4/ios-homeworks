import UIKit

/// Базовый протокол координатора.
/// Любой координатор управляет одним корневым контроллером (`controller`)  и может иметь дочерние координаторы (`children`), чтобы строить навигационный стек.
protocol Coordinator: AnyObject {
    /// Корневой контроллер текущего потока
    var controller: UIViewController { get set }
    /// Дочерние координаторы (для вложенных флоу).
    var children: [Coordinator] { get set }
    /// Точка входа конфигурации координатора.
    func setup()
}

/// Главный координатор приложения.
/// Отвечает за выбор стартового флоу: экран авторизации или основной, в зависимости от того, есть ли авторизованный пользователь и загружается ли его профиль.
final class AppCoordinator: Coordinator {
    /// Текущий корневой контроллер AppCoordinator.
    var controller: UIViewController
    /// Дочерние координаторы (login или main).
    var children: [Coordinator] = []
    
    private weak var window: UIWindow?
    
    /// Общий REST‑клиент, использующий authService для токена/refresh.
    private let restClient: SupabaseRESTClient
    /// Сервис работы с Supabase Auth (содержит текущую сессию / userID).
    private let authService: SupabaseAuthService
    /// OTP‑сервис (работа с кодами).
    private let otpService: SupabaseOTPService
    /// CheckerService, использующий authService + otpService.
    private let checkerService: CheckerServiceProtocol
    /// Работа с пользователями.
    private let userService: SupabaseUserService
    /// Кеш профиля пользователя.
    private let cacheStore: CDUserCache
    /// Сервис отслеживания сетевого статуса.
    private let networkService: NetworkStatusServiceProtocol
    /// Объект, инкапсулирующий логику проверки логина и загрузки профиля.
    private let loginInspector: LoginInspector
    
    /// Варианты стартового флоу приложения.
    enum Presentation {
        case login
        case main(user: User)
    }
    
    init(window: UIWindow) {
        self.window = window
        // 1. Auth
        self.authService = SupabaseAuthService()
        
        // 2. REST‑клиент
        let restClient = SupabaseRESTClient(authService: authService)
        self.restClient = restClient
        
        // 3. OTP + Checker
        self.otpService = SupabaseOTPService(client: restClient)
        self.checkerService = CheckerService(
            authService: authService,
            otpService: otpService
        )
        
        // 4. Кэш
        let userCache = CDUserCache()
        self.cacheStore = userCache
       
        // 5. UserService
        self.userService = SupabaseUserService(
            client: restClient,
            cacheStore: userCache
        )
        
        // 6. Network service
        self.networkService = NetworkStatusService.shared
        
        // 7. LoginInspector – создаём один раз и храним
        self.loginInspector = LoginInspector(
            checkerService: checkerService,
            userService: userService,
            authService: authService,
            userCache: userCache,
            networkService: networkService
        )
        
        // Пустой контроллер-заглушка, пока не выбран реальный флоу
        self.controller = StartViewController()
    }
    
    /// Точка входа: вызывается из SceneDelegate.
    func setup() {
        start()
    }
    
    /// Определяет, какой флоу запускать: если нет userID, то сразу логин; если userID есть, загружается профиль (онлайн/оффлайн), при успехе – main, при ошибках – логин.
    private func start() {
        // Есть ли текущий пользователь
        guard let _ = authService.userID else {
            // нет авторизованного пользователя -> сразу логин
            present(.login)
            return
        }
        
        // Пользователь есть – пробуем поднять профиль
        Task { @MainActor in
            do {
                let user = try await loginInspector.loadCurrentUserProfile()
                self.present(.main(user: user))
            } catch AppError.networkOffline {
                self.present(.login)
            } catch {
                self.present(.login)
            }
        }
    }
    
    /// Переключает текущее представление приложения: либо на login‑координатор, либо на main‑координатор.
    private func present(_ presentation: Presentation) {
        switch presentation {
        case .login:
            let factory = LoginFactory(loginInspector: loginInspector)
            let loginCoordinator = LoginCoordinator(factory: factory)
            loginCoordinator.delegate = self
            loginCoordinator.setup()
            // Сохраняем в children, чтобы не потерять координатор
            children = [loginCoordinator]
            controller = loginCoordinator.controller
            // Установить экран логина корневым
            setRoot(loginCoordinator.controller)
            
        case .main(let user):
            // Создаем основной координатор для уже авторизованного пользователя
            let mainCoordinator = MainCoordinator(
                user: user,
                authService: authService,
                userService: userService
            )
            mainCoordinator.delegate = self
            mainCoordinator.setup()
            children = [mainCoordinator]
            controller = mainCoordinator.controller
            // Устанавливаем основной флоу корневым
            setRoot(mainCoordinator.controller)
        }
    }
    
    /// Устанавливает переданный контроллер корневым в окне приложения.
    private func setRoot(_ root: UIViewController) {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController = root
            window.makeKeyAndVisible()
        }
    }
}

extension AppCoordinator: LoginCoordinatorDelegate {
    func loginCoordinator(_ coordinator: LoginCoordinator, didLogin user: User) {
        // Пользователь залогинен -> переход на .main
        present(.main(user: user))
    }
}

extension AppCoordinator: MainCoordinatorDelegate {
    func mainCoordinatorDidRequestLogout(_ coordinator: MainCoordinator) {
        // Пользователь разалогинился -> переход на .login
        present(.login)
    }
}
