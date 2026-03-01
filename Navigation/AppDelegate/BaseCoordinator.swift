import UIKit

protocol Coordinator: AnyObject {
    var controller: UIViewController { get set }
    var children: [Coordinator] { get set }

    func setup()
}
