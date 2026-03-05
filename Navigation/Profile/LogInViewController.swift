import UIKit

protocol LogInViewControllerDelegate {
    func check(login: String, password: String) -> Bool
}

final class LogInViewController: UIViewController {
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.isScrollEnabled = true
        
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let contentView = UIView()
        
        return contentView
    }()
    
    private lazy var divider: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        
        return view
    }()
    
    private lazy var image: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "logo")
        
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
        
        textField.delegate = self
        
        return textField
    }()
    
    private lazy var autorizationButton: UIButton = {
        let button = UIButton()
        let image = UIImage(named: "blue_pixel.png")
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
    
    private lazy var bruteForceButton = CustomButton(
        title: "Подобрать пароль",
        backgroundColor: .systemCyan,
        cornerRadius: 4.0
    ){ [weak self] in
        self?.didTapBruteForceButton()
    }
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        
        return indicator
    }()
    
    private lazy var logInStackView: UIStackView = { [unowned self] in
        let stackView = UIStackView()
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
    
    private let bruteForcer = PasswordBruteForcer()
    private var generatedPassword: String = ""
    private var userService: UserService?
    var loginDelegate: LogInViewControllerDelegate?
    var loginSuccess: ((User) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        addSubviews()
        setupConstraints()
        autoAuthorization()
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
        [
            scrollView,
            contentView,
            divider,
            image,
            logInTextField,
            passwordTextField,
            logInStackView,
            autorizationButton,
            bruteForceButton,
            activityIndicator
        ].forEach() {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [image, logInStackView, autorizationButton, bruteForceButton, activityIndicator].forEach() {
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
                
                activityIndicator.centerYAnchor.constraint(
                    equalTo: passwordTextField.centerYAnchor
                ),
                activityIndicator.trailingAnchor.constraint(
                    equalTo: passwordTextField.trailingAnchor,
                    constant: -8.0
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
                
                bruteForceButton.topAnchor.constraint(
                    equalTo: autorizationButton.bottomAnchor,
                    constant: 16.0
                ),
                bruteForceButton.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor,
                    constant: 16.0
                ),
                bruteForceButton.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor,
                    constant: -16.0
                ),
                bruteForceButton.heightAnchor.constraint(
                    equalToConstant: 50.0
                ),
                bruteForceButton.bottomAnchor.constraint(
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
    
    private func autoAuthorization() {
        #if DEBUG
        userService = TestUserService()
        logInTextField.text = "test"
        passwordTextField.text = "debug"
        #else
        let currentUser = User(
            login: "cat",
            fullName: "Cat Developer",
            avatar: UIImage(named: "SimpleCat") ?? UIImage(),
            status: "I'm cat ios-developer :)"
        )
        userService = CurrentUserService(user: currentUser)
        logInTextField.text = "cat"
        passwordTextField.text = "qwerty"
        #endif
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
    
    private func generateRandomPassword(length: Int) -> String {
        let chars = Array("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
        var result = ""
        for _ in 0..<length {
            if let char = chars.randomElement() {
                result.append(char)
            }
        }
        return result
    }
    
    @objc private func didTapBruteForceButton() {
        generatedPassword = generateRandomPassword(length: Int.random(in: 3...4))
        print("Generated password: \(generatedPassword)")
        
        passwordTextField.text = ""
        passwordTextField.isSecureTextEntry = true

        activityIndicator.startAnimating()
        bruteForceButton.isEnabled = false
        autorizationButton.isEnabled = false

        bruteForcer.bruteForce(
            target: generatedPassword,
            progress: { [weak self] attempt in
                self?.passwordTextField.text = attempt
            },
            completion: { [weak self] found in
                guard let self = self else { return }
                self.activityIndicator.stopAnimating()
                self.bruteForceButton.isEnabled = true
                self.autorizationButton.isEnabled = true
                self.passwordTextField.text = found
                self.passwordTextField.isSecureTextEntry = false
            }
        )
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
        loginSuccess?(user)
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

