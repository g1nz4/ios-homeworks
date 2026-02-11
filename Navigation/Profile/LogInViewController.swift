import UIKit

protocol LogInViewControllerDelegate {
    func check(login: String, password: String) -> Bool
}

final class LogInViewController: UIViewController {
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.isScrollEnabled = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        return contentView
    }()
    
    private lazy var divider: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    private lazy var image: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "logo")
        image.translatesAutoresizingMaskIntoConstraints = false
        
        return image
    }()
    
    private lazy var logInTextField: UITextField = { [unowned self] in
        let textField = UITextField()
        textField.textColor = .black
        textField.font = UIFont.systemFont(ofSize: 16.0)
        textField.placeholder = "Email of phone"
        textField.tintColor = .tintColor
        textField.autocapitalizationType = .none
        textField.keyboardType = UIKeyboardType.default
        textField.returnKeyType = UIReturnKeyType.done
        textField.backgroundColor = .systemGray6
        textField.borderStyle = .none
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        textField.delegate = self
        
        return textField
    }()
    
    private lazy var passwordTextField: UITextField = { [unowned self] in
        let textField = UITextField()
        textField.textColor = .black
        textField.font = UIFont.systemFont(ofSize: 16.0)
        textField.placeholder = "Password"
        textField.tintColor = .tintColor
        textField.autocapitalizationType = .none
        textField.keyboardType = UIKeyboardType.default
        textField.returnKeyType = UIReturnKeyType.done
        textField.backgroundColor = .systemGray6
        textField.isSecureTextEntry = true
        textField.borderStyle = .none
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        textField.delegate = self
        
        return textField
    }()
    
    private lazy var autorizationButton: UIButton = {
        let button = UIButton()
        let image = UIImage(named: "blue_pixel.png")
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        button.layer.cornerRadius = 10.0
        button.setTitle("Log In", for: .normal)
        button.setBackgroundImage(image, for: .normal)
        button.alpha = {
            if button.state == .normal {
                button.alpha = 1.0
            } else if button.state == .highlighted || button.state == .selected || button.state == .disabled {
                button.alpha = 0.8
            }
            return button.alpha
        }()
        button.addTarget(self, action: #selector(didTapAutorizationButton(_:)), for: .touchUpInside)
        
        return button
    }()
    
    private lazy var logInStackView: UIStackView = { [unowned self] in
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.clipsToBounds = true
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        stackView.spacing = 0.0
        stackView.layer.cornerRadius = 10.0
        stackView.layer.borderColor = UIColor.lightGray.cgColor
        stackView.layer.borderWidth = 0.5
        
        stackView.addArrangedSubview(self.logInTextField)
        stackView.addArrangedSubview(self.passwordTextField)
        stackView.addSubview(self.divider)
        
        return stackView
    }()
    
    private var userService: UserService?
    var loginDelegate: LogInViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        addSubviews()
        setupConstraints()
        setupUserService()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupKeyboardObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        removeKeyboardObservers()
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.isHidden = true
    }
    
    private func addSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [image, logInStackView, autorizationButton].forEach() {
            contentView.addSubview($0)
        }
    }
    
    private func setupConstraints() {
        let safeAreaGuide = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate(
            [
                scrollView.leadingAnchor.constraint(
                    equalTo: safeAreaGuide.leadingAnchor
                ),
                scrollView.trailingAnchor.constraint(
                    equalTo: safeAreaGuide.trailingAnchor
                ),
                scrollView.topAnchor.constraint(
                    equalTo: safeAreaGuide.topAnchor
                ),
                scrollView.bottomAnchor.constraint(
                    equalTo: safeAreaGuide.bottomAnchor
                ),
                
                contentView.leadingAnchor.constraint(
                    equalTo: scrollView.leadingAnchor
                ),
                contentView.trailingAnchor.constraint(
                    equalTo: scrollView.trailingAnchor
                ),
                contentView.topAnchor.constraint(
                    equalTo: scrollView.topAnchor
                ),
                contentView.bottomAnchor.constraint(
                    equalTo: scrollView.bottomAnchor
                ),
                contentView.widthAnchor.constraint(
                    equalTo: scrollView.widthAnchor
                ),
                
                image.topAnchor.constraint(
                    equalTo: contentView.topAnchor,
                    constant: 120.0
                ),
                image.centerXAnchor.constraint(
                    equalTo: contentView.centerXAnchor
                ),
                image.widthAnchor.constraint(
                    equalToConstant: 100.0
                ),
                image.heightAnchor.constraint(
                    equalToConstant: 100.0
                ),
                
                logInTextField.leadingAnchor.constraint(
                    equalTo: logInStackView.leadingAnchor
                ),
                logInTextField.trailingAnchor.constraint(
                    equalTo: logInStackView.trailingAnchor
                ),
                logInTextField.topAnchor.constraint(
                    equalTo: logInStackView.topAnchor
                ),
                logInTextField.heightAnchor.constraint(
                    equalToConstant: 50.0
                ),
                
                passwordTextField.leadingAnchor.constraint(
                    equalTo: logInStackView.leadingAnchor
                ),
                passwordTextField.trailingAnchor.constraint(
                    equalTo: logInStackView.trailingAnchor
                ),
                passwordTextField.topAnchor.constraint(
                    equalTo: logInTextField.bottomAnchor
                ),
                passwordTextField.heightAnchor.constraint(
                    equalToConstant: 50.0
                ),
                
                logInStackView.topAnchor.constraint(
                    equalTo: image.bottomAnchor,
                    constant: 120.0
                ),
                logInStackView.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor,
                    constant: 16.0
                ),
                logInStackView.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor,
                    constant: -16.0
                ),
                logInStackView.heightAnchor.constraint(
                    equalToConstant: 100.0
                ),
                
                divider.topAnchor.constraint(
                    equalTo: logInStackView.topAnchor,
                    constant: 50.0
                ),
                divider.leadingAnchor.constraint(
                    equalTo: logInStackView.leadingAnchor
                ),
                divider.trailingAnchor.constraint(
                    equalTo: logInStackView.trailingAnchor
                ),
                divider.heightAnchor.constraint(
                    equalToConstant: 0.5
                ),
                
                autorizationButton.topAnchor.constraint(
                    equalTo: logInStackView.bottomAnchor,
                    constant: 16.0
                ),
                autorizationButton.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor,
                    constant: 16.0
                ),
                autorizationButton.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor,
                    constant: -16.0
                ),
                autorizationButton.heightAnchor.constraint(
                    equalToConstant: 50.0
                ),
                autorizationButton.bottomAnchor.constraint(
                    equalTo: contentView.bottomAnchor
                )
            ]
        )
    }
    
    private func setupKeyboardObservers() {
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(
            self,
            selector: #selector(self.willShowKeyboard(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        notificationCenter.addObserver(
            self,
            selector: #selector(self.willHideKeyboard(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func removeKeyboardObservers() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self)
    }
    
    private func setupUserService() {
        #if DEBUG
        userService = TestUserService()
        #else
        let currentUser = User(
                login: "cat",
                fullName: "Cat Developer",
                avatar: UIImage(named: "SimpleCat") ?? UIImage(),
                status: "I'm cat ios-developer :)"
            )
        userService = CurrentUserService(user: currentUser)
        #endif
    }
    
    private func showMainTabBar(user: User) {
        let tabBarController = MainTabBarController(user: user)
        
        guard let windowScene = view.window?.windowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate,
              let window = sceneDelegate.window else { return }
     
       window.rootViewController = tabBarController
    }
    private func showAlert(message: String) {
            let alert = UIAlertController(
                title: nil,
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
    }
    
    @objc func didTapAutorizationButton(_ sender: UIButton) {
        guard let loginText = logInTextField.text, !loginText.isEmpty,
              let passwordText = passwordTextField.text, !passwordText.isEmpty else {
                showAlert(message: "Введите логин и пароль")
                return
        }
        guard let user = userService?.getUser(login: loginText) else {
            showAlert(message: "Пользователь не найден")
            return
        }
        guard let validation = loginDelegate?.check(login: loginText, password: passwordText),
            validation else {
            showAlert(message: "Неверный пароль")
            return
        }
        showMainTabBar(user: user)
    }
    
    @objc func willShowKeyboard(_ notification: NSNotification) {
        let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height
        scrollView.contentInset.bottom += keyboardHeight ?? 0.0
    }
    
    @objc func willHideKeyboard(_ notification: NSNotification) {
        scrollView.contentInset.bottom = 0.0
    }
}
   
extension LogInViewController: UITextFieldDelegate {
   
   func textFieldShouldReturn(
       _ textField: UITextField
   ) -> Bool {
       textField.resignFirstResponder()

       return true
   }
}

