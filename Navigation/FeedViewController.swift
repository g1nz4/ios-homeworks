import UIKit

struct Post {
    var title: String
}

final class FeedViewController: UIViewController {

    let post = Post(title:"Hello World!")
    
    private lazy var buttonOne = CustomButton(
        title: "Перейти"
    ){ [weak self] in
        self?.buttonPressed()
    }
    
    private lazy var buttonTwo = CustomButton(
        title: "Открыть"
    ){ [weak self] in
        self?.buttonPressed()
    }

    private lazy var feedStackView: UIStackView = { [unowned self] in
        let stackView = UIStackView()
        stackView.clipsToBounds = true
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        stackView.spacing = 10.0
        stackView.addArrangedSubview(self.buttonOne)
        stackView.addArrangedSubview(self.buttonTwo)
            
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        title = "Лента"
        
        setupActionButton()
    }
     
    private func setupActionButton() {
        [buttonOne, buttonTwo, feedStackView].forEach() {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        view.addSubview(feedStackView)
        
        let safeAreaLayoutGuide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate(
            [
                feedStackView.leadingAnchor.constraint(
                    equalTo: safeAreaLayoutGuide.leadingAnchor,
                    constant: 16.0
                ),
                feedStackView.trailingAnchor.constraint(
                    equalTo: safeAreaLayoutGuide.trailingAnchor,
                    constant: -16.0
                ),
                feedStackView.centerYAnchor.constraint(
                    equalTo: safeAreaLayoutGuide.centerYAnchor
                ),
                feedStackView.centerXAnchor.constraint(
                    equalTo: safeAreaLayoutGuide.centerXAnchor
                ),
        
                buttonOne.widthAnchor.constraint(
                    equalToConstant: 350.0
                ),
                buttonOne.heightAnchor.constraint(
                    equalToConstant: 50.0
                ),
                
                buttonTwo.widthAnchor.constraint(
                    equalToConstant: 350.0
                ),
                buttonTwo.heightAnchor.constraint(
                    equalToConstant: 50.0
                ),
            ]
        )
    }
    
    private func buttonPressed() {
        let postViewController = PostViewController()
        postViewController.postTitle = post
        navigationController?.pushViewController(postViewController, animated: true)
    }
}
