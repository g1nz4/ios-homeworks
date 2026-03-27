import UIKit

protocol LogInViewControllerDelegate: AnyObject {
    func checkCredentials(
        email: String,
        password: String,
        completion: @escaping (Result<Void, Error>) -> Void
    )
    
    func signUp(
        email: String,
        password: String,
        completion: @escaping (Result<Void, Error>) -> Void
    )
}

final class LogInViewController: UIViewController {
    
    weak var coordinator: LoginCoordinator?
    private var viewModel: LoginViewModelProtocol
    
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
    
    private lazy var emailTextField: UITextField = { [unowned self] in
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
        textField.addTarget(self, action: #selector(textFieldsDidChange), for: .editingChanged)
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
        textField.addTarget(self, action: #selector(textFieldsDidChange), for: .editingChanged)
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
        button.setTitle("Войти", for: .normal)
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
    
    private lazy var signUpButton: UIButton = {
        let button = UIButton()
        let image = UIImage(named: "blue_pixel.png")
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        button.layer.cornerRadius = 10.0
        button.setTitle("Зарегистрироваться", for: .normal)
        button.setBackgroundImage(image, for: .normal)
        button.addTarget(self, action: #selector(didTapSignUpButton), for: .touchUpInside)
        
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
        
        stackView.addArrangedSubview(self.emailTextField)
        stackView.addArrangedSubview(self.passwordTextField)
        stackView.addSubview(self.divider)
        
        return stackView
    }()
    
    init(delegate: LogInViewControllerDelegate) {
        self.viewModel = LoginViewModel(loginDelegate: delegate)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        addSubviews()
        setupConstraints()
        autoAuthorization()
        bindingViewModel()
        updateStateAuthorizationButton()
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
    
    private func bindingViewModel() {
        viewModel.isLoading.binding { [weak self] isLoading in
            DispatchQueue.main.async {
                self?.updateStateAuthorizationButton(isLoad: isLoading)
            }
        }

        viewModel.errorText.binding { [weak self] text in
            guard let text, !text.isEmpty else { return }
            DispatchQueue.main.async {
                self?.showAlert(message: text)
            }
        }
        
        viewModel.onSuccess = { [weak self] user in
            self?.coordinator?.didLogin(user: user)
        }
    }
    
    private func addSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [image, logInStackView, autorizationButton, signUpButton].forEach() {
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
                
                emailTextField.leadingAnchor.constraint(
                    equalTo: logInStackView.leadingAnchor
                ),
                emailTextField.trailingAnchor.constraint(
                    equalTo: logInStackView.trailingAnchor
                ),
                emailTextField.topAnchor.constraint(
                    equalTo: logInStackView.topAnchor
                ),
                emailTextField.heightAnchor.constraint(
                    equalToConstant: 50.0
                ),
                
                passwordTextField.leadingAnchor.constraint(
                    equalTo: logInStackView.leadingAnchor
                ),
                passwordTextField.trailingAnchor.constraint(
                    equalTo: logInStackView.trailingAnchor
                ),
                passwordTextField.topAnchor.constraint(
                    equalTo: emailTextField.bottomAnchor
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
                signUpButton.topAnchor.constraint(
                    equalTo: autorizationButton.bottomAnchor,
                    constant: 16.0
                ),
                signUpButton.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor,
                    constant: 16.0
                ),
                signUpButton.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor,
                    constant: -16.0
                ),
                signUpButton.bottomAnchor.constraint(
                    equalTo: contentView.bottomAnchor,
                    constant: -20.0
                ),
                signUpButton.heightAnchor.constraint(equalToConstant: 50.0)
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
        let userService = TestUserService()
        emailTextField.text = "test@test.ru"
        passwordTextField.text = "123456"
        #else
        let currentUser = User(
            login: "cat",
            fullName: "Cat Developer",
            avatar: UIImage(named: "SimpleCat") ?? UIImage(),
            status: "I'm cat ios-developer :)"
        )
        userService = CurrentUserService(user: currentUser)
        emailTextField.text = "cat@developer.ru"
        passwordTextField.text = "qwerty"
        #endif
    }
    
    private func updateStateAuthorizationButton(isLoad: Bool? = nil) {
        let email = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        
        let hasEmail = !email.isEmpty
        let hasPassword = !password.isEmpty
        let isLoadNow = isLoad ?? viewModel.isLoading.value
        let tap = hasEmail && hasPassword && !isLoadNow
        
        autorizationButton.isEnabled = tap
        autorizationButton.alpha = tap ? 1.0 : 0.9
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc func didTapAutorizationButton(_ sender: UIButton) {
        viewModel.email = emailTextField.text ?? ""
        viewModel.password = passwordTextField.text ?? ""
        viewModel.login()
    }
    
    @objc private func didTapSignUpButton() {
        coordinator?.present(.signUp)
    }
    
    @objc private func textFieldsDidChange(_ textField: UITextField) {
        updateStateAuthorizationButton()
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

