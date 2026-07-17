import UIKit

/// Координатор экрана музыки.
final class MusicCoordinator: Coordinator {
    
    /// Корневой контроллер координатора.
    var controller: UIViewController
    
    /// Дочерние координаторы.
    var children: [Coordinator] = []
    
    /// Контейнер корневых вкладок приложения.
    private let rootTabController: RootTabContainerController
    
    /// Локальный UINavigationController для стека экранов раздела
    private let navController: UINavigationController
    
    /// Сервис музыкального плеера (воспроизведение, пауза, переключение треков и т.п.).
    private let player: MusicPlayerService
    
    /// ViewModel основного экрана списка музыки.
    private let musicViewModel: MusicViewModel
    
    /// ViewModel мини‑плеера (нижняя панель с текущим треком).
    private let miniPlayerViewModel: MiniPlayerViewModel
    
    init(
        rootTabController: RootTabContainerController,
        navigationController: UINavigationController,
        player: MusicPlayerService,
        musicViewModel: MusicViewModel,
        miniPlayerViewModel: MiniPlayerViewModel
    ) {
        self.rootTabController = rootTabController
        self.navController = navigationController
        self.controller = navigationController
        
        self.player = player
        self.musicViewModel = musicViewModel
        self.miniPlayerViewModel = miniPlayerViewModel
        
        let musicVC = MusicCollectionViewController(
            viewModel: musicViewModel,
            presentationStyle: .tabRoot
        )
        
        musicVC.coordinator = self
        
        navigationController.viewControllers = [musicVC]
    }

    /// Точка входа конфигурации координатора.
    func setup() {
        navController.setNavigationBarHidden(false, animated: false)
    }
}
