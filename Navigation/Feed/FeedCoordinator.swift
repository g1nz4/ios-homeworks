import UIKit

/// Координатор ленты: управляет стеком навигации вкладки `Лента`.
final class FeedCoordinator: Coordinator {
    
    var controller: UIViewController
    var children: [Coordinator]
    
    /// Навигационный контроллер вкладки Лента.
    let navController: UINavigationController
    
    /// Слабая ссылка на основной экран ленты.
    private weak var feedVC: FeedCollectionViewController?
    private var feedVM: MainFeedViewModel
    
    private let storyViewerFactory: StoryViewerFactory
    
    enum Presentation {
        case storyViewer(story: FeedStory)
        case photoViewer(photos: [Photo], startIndex: Int, showAddToSaved: Bool, viewInPost: Bool)
    }
    
    /// Принимаем уже собранный контроллер ленты
    init(
        rootViewController: FeedCollectionViewController,
        feedVM: MainFeedViewModel,
        storyViewerFactory: StoryViewerFactory
    ) {
        self.navController = UINavigationController(rootViewController: rootViewController)
        self.controller = navController
        self.children = []
        self.feedVC = rootViewController
        self.feedVM = feedVM
        
        self.storyViewerFactory = storyViewerFactory
        
        rootViewController.coordinator = self
        
       
        
        setup()
    }
    
    func setup() {
        navController.setNavigationBarHidden(false, animated: false)
    }
    
    func present(_ presentation: Presentation) {
        switch presentation {

        case let .storyViewer(story):
            Task { [weak self] in
                guard let self else { return }
                guard let vc = await self.storyViewerFactory.makeViewerForFeed(story: story) else {
                    return
                }
                vc.modalPresentationStyle = .fullScreen
                self.navController.present(vc, animated: true)
            }
        case let .photoViewer(photos, startIndex, showAddToSaved, viewInPost):
            let vc = PhotosViewerViewController(
                photos: photos,
                startIndex: startIndex,
                showAddToSaved: showAddToSaved,
                viewInPost: viewInPost
            )
            vc.delegate = self
            navController.pushViewController(vc, animated: true)
        }
    }
    
    func dismiss() {
        navController.dismiss(animated: true)
    }
}



extension FeedCoordinator: PhotoViewerViewControllerDelegate {
    /// Пользователь выбрал `Сделать фото аватаром` в меню полноэкранного просмотра фото.
    func photoViewer(
        _ vc: PhotosViewerViewController,
        didChooseAvatarFrom photo: Photo
    ) { }
    
    /// Пользователь выбрал `Сделать обложкой профиля` в меню полноэкранного просмотра фото.
    func photoViewer(
        _ vc: PhotosViewerViewController,
        didChooseCoverFrom photo: Photo
    ) { }
    
    /// Пользователь добавил фото в `Сохранённые`.
    func photoViewer(
        _ vc: PhotosViewerViewController,
        didAddToSaved photo: Photo
    ) {
        Task { [weak self] in
            await self?.feedVM.addToSaved(photo: photo)
            NotificationCenter.default.post(name: .savedPhotosDidChange, object: nil)
        }
    }
    
    /// Пользователь удалил фото.
    func photoViewer(
        _ vc: PhotosViewerViewController,
        didDelete photo: Photo
    ) { }
}
