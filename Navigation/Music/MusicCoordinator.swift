import UIKit

final class MusicCoordinator: Coordinator {

    var controller: UIViewController
    var children: [Coordinator] = []

    init() {
//        let storage = MusicStorage()
//        let viewModel = MusicViewModel(storage: storage)
//        let musicVC = MusicViewController(viewModel: viewModel)
//        musicVC.tabBarItem = UITabBarItem(
//            title: "Музыка",
//            image: UIImage(systemName: "music.note"),
//            selectedImage: UIImage(systemName: "music.note.list")
//        )
        controller = UIViewController()
    }

    func setup() { }
}
