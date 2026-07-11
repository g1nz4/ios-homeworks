import UIKit
/// Стартовый экран авторизации.
/// Показывает: логотип и две кнопки: "Вход" и "Регистрация".
final class AuthStartViewController: BaseScrollViewController {
    
    weak var coordinator: LoginCoordinator?
    
    private lazy var logo: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "logo")
        image.clipsToBounds = true
    
        return image
    }()
    
    private lazy var loginButton = PrimaryActionButton(
        title: NSLocalizedString("login_button_title", comment: "Кнопка входа"),
        style: .inverted
    )
    
    private lazy var signUpButton = PrimaryActionButton(
        title: NSLocalizedString("signup_button_title", comment: "Кнопка регистрации"),
        style: .inverted
    )
    
    private lazy var stackButton: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [loginButton, signUpButton])
        stack.axis = .vertical
        stack.spacing = 16.0
        stack.alignment = .fill
        
        return stack
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .app
        navigationController?.navigationBar.isHidden = true
        
        setupButtons()
    }
    
    override func configureContent() {
        super.configureContent()
        
        [logo, stackButton].forEach() {
            $0.translatesAutoresizingMaskIntoConstraints = false
          contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            logo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logo.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logo.widthAnchor.constraint(equalToConstant: 120),
            logo.heightAnchor.constraint(equalToConstant: 120),
           
            stackButton.topAnchor.constraint(equalTo: logo.bottomAnchor, constant: 150.0),
            stackButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16.0),
            stackButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16.0),
            stackButton.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -32.0)
        ])
    }
    
    private func setupButtons() {
        loginButton.setAction { [weak self] in
            self?.didTapLogin()
        }
        
        signUpButton.setAction { [weak self] in
            self?.didTapSignUp()
        }
    }
    
    @objc private func didTapLogin() {
        coordinator?.present(.loginCredentials)
    }

    @objc private func didTapSignUp() {
        coordinator?.present(.signUp)
    }
}
