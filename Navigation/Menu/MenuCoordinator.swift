import UIKit

final class MenuCoordinator: Coordinator {

    var controller: UIViewController
    var children: [Coordinator] = []

    let menuVC: MenuCollectionViewController
    let menuNC: UINavigationController
    
    init() {
        children = []
        
        menuVC = MenuCollectionViewController()
        menuNC = UINavigationController(rootViewController: menuVC)
        
        self.controller = menuNC
    }

    func setup() {}
}
