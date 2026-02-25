import UIKit

typealias Action = () -> Void

enum ShowStyle {
    case push
    case present
}

protocol FlowCoordinator: AnyObject {
    var parentCoordinator: MainBaseCoordinator? { get set }
}

protocol Coordinator: FlowCoordinator {
    var rootViewController: UIViewController? { get set }
    
    func start() -> UIViewController
    
    @discardableResult
    func resetToRoot() -> Self
}

extension Coordinator {
    var navigationViewController: UINavigationController? {
        get {
            (rootViewController as? UINavigationController)
        }
    }
    
    @discardableResult
    func resetToRoot() -> Self {
        navigationViewController?.popToRootViewController(animated: false)
        return self
    }
    
    func show(
        viewController: UIViewController,
        style: ShowStyle,
        animated: Bool = true
    ) {
        switch style {
        case .push:
            navigationViewController?.pushViewController(viewController, animated: animated)
        case .present:
            navigationViewController?.present(viewController, animated: animated)
        }
    }
    
    func hide(
       style: ShowStyle,
       animated: Bool = true
   ) {
       switch style {
       case .push:
           navigationViewController?.popViewController(animated: animated)
       case .present:
           navigationViewController?.dismiss(animated: animated)
       }
   }
}

protocol ProfileBaseCoordinator: Coordinator {
    func showProfileScreen()
}

protocol FeedBaseCoordinator: Coordinator {
    func showFeedScreen()
}

protocol MainBaseCoordinator: AnyObject {
    var profileCoordinator: ProfileBaseCoordinator { get }
    var feedCoordinator: FeedBaseCoordinator { get }
    
    func moveTo(flow: AppFlow)
}
