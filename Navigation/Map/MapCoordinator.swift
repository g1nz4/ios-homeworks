import UIKit

final class MapCoordinator: Coordinator {

    var controller: UIViewController
    var children: [Coordinator] = []

    let mapVC: MapViewController
    let mapNC: UINavigationController
    
    init() {
        children = []
        
        mapVC = MapViewController()
        mapNC = UINavigationController(rootViewController: mapVC)
        mapVC.tabBarItem = UITabBarItem(
            title: "Карта",
            image: UIImage(systemName: "map"),
            selectedImage: UIImage(systemName: "map.fill")
        )
        controller = mapNC
    }

    func setup() {}
}
