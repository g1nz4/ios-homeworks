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
    /// Доменный слой авторизации / профиля.
    private let loginInspector: LoginInspector
    /// Сервис работы с Supabase Auth (содержит текущую сессию / userID).
    private let authService: SupabaseAuthService
    
    /// Возможные сценарии, которые может показать AppCoordinator.
    enum Presentation {
        case login
        case main(user: User)
    }
    
    init(
        loginInspector: LoginInspector = LoginInspector(),
        authService: SupabaseAuthService = SupabaseAuthService.shared
    ) {
        self.loginInspector = loginInspector
        self.authService = authService
        // Пустой контроллер-заглушка, пока не выбрали реальный флоу
        self.controller = UIViewController()
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
        
        // Пользователь есть – пробуем поднять профиль (онлайн Supabase/оффлайн кеш)
        Task { @MainActor in
            do {
                let user = try await loginInspector.loadCurrentUserProfile()
                self.present(.main(user: user))
            } catch AppError.networkOffline {
                // нет ни сети, ни кеша -> логин
                self.present(.login)
            } catch {
                // сессия битая / сломанный профиль, не загрузилось и т.п. –> логин
                self.present(.login)
            }
        }
    }
    
    /// Переключает текущее представление приложения: либо на login‑координатор, либо на main‑координатор.
    private func present(_ presentation: Presentation) {
        switch presentation {
        case .login:
            let factory = MyLoginFactory()
            let loginCoordinator = LoginCoordinator(factory: factory)
            loginCoordinator.setup()
            // Сохраняем в children, чтобы не потерять координатор
            children = [loginCoordinator]
            controller = loginCoordinator.controller
            // Установить экран логина корневым
            setRoot(loginCoordinator.controller)
            
        case .main(let user):
            // Создаем основной координатор для уже авторизованного пользователя
            let mainCoordinator = MainCoordinator(user: user)
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
