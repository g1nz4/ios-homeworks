import UIKit

class ProfileViewController: UIViewController {

    private lazy var profileHeaderView: ProfileHeaderView = {
        let view = ProfileHeaderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var button: UIButton = {
       let button = UIButton()
        button.setTitle("New Button", for: .normal)
        button.layer.backgroundColor = UIColor.systemBlue.cgColor
        button.setTitleColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .lightGray
        title = "Профиль"
        
        setupButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        setupProfileHeaderView()
    }

    private func setupProfileHeaderView() {
        view.addSubview(profileHeaderView)
        
        NSLayoutConstraint.activate(
            [
            profileHeaderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            profileHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            profileHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            profileHeaderView.heightAnchor.constraint(equalToConstant: 220)
            ]
        )
    }
    
    private func setupButton() {
        view.addSubview(button)
        
        let safeAreaLayoutGuide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate(
            [
            button.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor,constant: 0.0),
            button.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: 0.0),
            button.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            button.heightAnchor.constraint(equalToConstant: 50.0)
            ]
        )
    }
}
