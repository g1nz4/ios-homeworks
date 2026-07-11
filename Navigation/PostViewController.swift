import UIKit

final class PostViewController: UIViewController {
    
    weak var coordinator: FeedCoordinator?
    
    private lazy var actionButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("info", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemYellow
    //    setupBarButtonItem()
    }
    
//    private func setupBarButtonItem() {
//        navigationItem.rightBarButtonItem = UIBarButtonItem(
//            title: "Info",
//            style: .plain,
//            target: self,
//            action: #selector(infoButtonPressed(_:))
//        )
//    }
    
    //    @objc func infoButtonPressed(_ sender: UIButton) {
    //        coordinator?.present(.info)
    //    }
    //}
}
