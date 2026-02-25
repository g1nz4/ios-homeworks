import UIKit

final class PostViewController: UIViewController {
    var showInfo: (() -> Void)?
    var onBack: (() -> Void)?
    
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
        setupBarButtonItem()
    }
    
    private func setupBarButtonItem() {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Info",
            style: .plain,
            target: self,
            action: #selector(infoButtonPressed(_:))
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(
        title: "Back",
        style: .plain,
        target: self,
        action: #selector(backButtonPressed(_:))
    )
    }
    
    @objc func infoButtonPressed(_ sender: UIButton) {
        showInfo?()
    }
    
    @objc func backButtonPressed(_ sender: UIButton) {
        onBack?()
    }
}
