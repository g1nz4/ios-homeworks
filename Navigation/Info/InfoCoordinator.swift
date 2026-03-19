import UIKit

final class InfoCoordinator: Coordinator {
    
    var controller: UIViewController
    var children: [Coordinator]
    
    let infoVC: InfoViewController
    let infoNC: UINavigationController
    
    init() {
        children = []
        
        let viewModel = ResidentsViewModel()
        infoVC = InfoViewController(viewModel: viewModel)
        infoNC = UINavigationController(rootViewController: infoVC)
        infoNC.tabBarItem = UITabBarItem(
            title: "Info",
            image: UIImage(systemName: "info.circle"),
            selectedImage: UIImage(systemName: "info.circle.fill")
        )
        controller = infoNC
        setup()
    }
    
    func setup() {
        infoVC.coordinator = self
    }
}
