import UIKit

class PostViewController: UIViewController {

    var postTitle: Post?
    
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
        self.title = postTitle?.title
        
        setupRightBarButtonItem()
    }
    
    private func setupRightBarButtonItem() {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Info",
            style: .plain,
            target: self,
            action: #selector(buttonPressed(_:))
        )
    }
    
    @objc func buttonPressed(_ sender: UIButton) {
        let infoViewController = InfoViewController()
        
        infoViewController.modalTransitionStyle = .flipHorizontal
        infoViewController.modalPresentationStyle = .pageSheet
       
        present(infoViewController, animated: true)
    }
}
