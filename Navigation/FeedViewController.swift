import UIKit

struct Post {
    var title: String
}

final class FeedViewController: UIViewController {

    let post = Post(title:"Hello World!")
    
    private lazy var buttonStackViewOne: UIButton = {
        let button = UIButton()
        button.setTitle("Перейти", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.backgroundColor = UIColor.systemBlue.cgColor
        button.layer.cornerRadius = 8.0
        
        return button
    }()
    
    private lazy var buttonStackViewTwo: UIButton = {
        let button = UIButton()
        button.setTitle("Открыть", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.backgroundColor = UIColor.systemBlue.cgColor
        button.layer.cornerRadius = 8.0
        
        return button
    }()
    
    private lazy var feedStackView: UIStackView = { [unowned self] in
        let stackView = UIStackView()
            
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.clipsToBounds = true
            
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        stackView.spacing = 10.0
                
        stackView.addArrangedSubview(self.buttonStackViewOne)
        stackView.addArrangedSubview(self.buttonStackViewTwo)
            
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        title = "Лента"
        
        setupActionButton()
    }
     
    private func setupActionButton() {
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
        
                buttonStackViewOne.widthAnchor.constraint(
                    equalToConstant: 350.0
                ),
                buttonStackViewOne.heightAnchor.constraint(
                    equalToConstant: 50.0
                ),
                
                buttonStackViewTwo.widthAnchor.constraint(
                    equalToConstant: 350.0
                ),
                buttonStackViewTwo.heightAnchor.constraint(
                    equalToConstant: 50.0
                ),
            ]
        )
       
        buttonStackViewOne.addTarget(
            self,
            action: #selector(buttonPressed(_:)),
            for: .touchUpInside
        )
        buttonStackViewTwo.addTarget(
            self,
            action: #selector(buttonPressed(_:)),
            for: .touchUpInside
        )
    }
    
    @objc func buttonPressed(_ sender: UIButton) {
        let postViewController = PostViewController()
        postViewController.postTitle = post
        navigationController?.pushViewController(postViewController, animated: true)
    }
}
