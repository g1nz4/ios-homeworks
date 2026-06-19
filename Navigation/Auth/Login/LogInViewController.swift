import UIKit

/// Контракт взаимодействия между UI-слоем авторизации и бизнес-логикой (LoginInspector).
protocol LoginDelegateProtocol: AnyObject {
    func checkCredentials(email: String, password: String) async throws
    func signUp(_ data: SignUpData) async throws -> User
    func sendSMSCode(to phone: String) async throws -> String
    func verifySMSCode(verificationID: String, code: String) async throws
    func loadCurrentUserProfile() async throws -> User
    func loginByPhone(_ phone: String) async throws -> User
}

/// Экран авторизации по email.
@MainActor
final class LogInViewController: BaseScrollViewController {
    
    weak var coordinator: LoginCoordinator?
   
    private let viewModel: LoginViewModel
    
    private lazy var label: UILabel = {
       let label = UILabel()
       label.text = "С возвращением"
       label.textColor = .appPrimaryText
       label.font = UIFont.systemFont(ofSize: 18.0, weight: .bold)
       
       return label
   }()
   
   private lazy var descriptionLabel: UILabel = {
       let label = UILabel()
       label.text = "Введите email и пароль для входа в приложение"
       label.numberOfLines = 0
       label.textColor = .appPrimaryText
       label.font = UIFont.systemFont(ofSize: 14.0, weight: .medium)
       label.textAlignment = .center
       
       return label
   }()
    
    private lazy var divider: UIView = {
        let view = UIView()
        view.backgroundColor = .appSeparator
        
        return view
    }()
    
    private lazy var emailTextField: UITextField = { [unowned self] in
        let textField = UITextField()
        textField.textColor = .appPrimaryText
        textField.font = UIFont.systemFont(ofSize: 16.0)
        textField.tintColor = .appAccent
        textField.autocapitalizationType = .none
        textField.keyboardType = .default
        textField.returnKeyType = .done
        textField.backgroundColor = .appTextFieldBackground
        textField.borderStyle = .none
        textField.addTarget(self, action: #selector(textFieldsDidChange), for: .editingChanged)
        textField.delegate = self
        
        textField.attributedPlaceholder = NSAttributedString(
            string: "Email",
            attributes: [.foregroundColor: UIColor.appSecondaryText]
        )
        
        return textField
    }()
    
    private lazy var passwordTextField: UITextField = { [unowned self] in
        let textField = UITextField()
        textField.textColor = .appPrimaryText
        textField.font = UIFont.systemFont(ofSize: 16.0)
        textField.tintColor = .appAccent
        textField.autocapitalizationType = .none
        textField.keyboardType = .default
        textField.returnKeyType = .done
        textField.backgroundColor = .appTextFieldBackground
        textField.isSecureTextEntry = true
        textField.borderStyle = .none
        textField.addTarget(self, action: #selector(textFieldsDidChange), for: .editingChanged)
        textField.delegate = self
        
        textField.attributedPlaceholder = NSAttributedString(
            string: "Password",
            attributes: [.foregroundColor: UIColor.appSecondaryText]
        )

        return textField
    }()
    
    private lazy var logInStackView: UIStackView = { [unowned self] in
        let stackView = UIStackView()
        stackView.clipsToBounds = true
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        stackView.spacing = 0.0
        stackView.layer.cornerRadius = 10.0
        stackView.layer.borderColor = UIColor.appSeparator.cgColor
        stackView.layer.borderWidth = 0.5
        stackView.backgroundColor = .appSecondaryBackground
        
        stackView.addArrangedSubview(self.emailTextField)
        stackView.addArrangedSubview(self.passwordTextField)
        stackView.addSubview(self.divider)
        
        return stackView
    }()
    
    private lazy var loginButton = PrimaryActionButton(
       title: NSLocalizedString("login_button_title", comment: "Кнопка входа")
   )
   
   private lazy var loginByPhoneTextButton: UIButton = {
       let button = UIButton(type: .system)
       button.setTitle("Войти по номеру телефона", for: .normal)
       button.titleLabel?.font = UIFont.systemFont(ofSize: 14.0, weight: .medium)
       button.tintColor = .appAccent
       button.addTarget(self, action: #selector(didTapLoginByPhone), for: .touchUpInside)
       
       return button
   }()
    
    init(delegate: LoginDelegateProtocol) {
        self.viewModel = LoginViewModel(delegate: delegate)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .appBackground
        navigationController?.navigationBar.isHidden = true

        setupLoginButton()
        bindViewModel()
        autofill()
        updateStateLoginButton()
    }
    
    override func configureContent() {
        [label,
         descriptionLabel,
         logInStackView,
         loginButton,
         loginByPhoneTextButton].forEach() {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 210),
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20.0),
            descriptionLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            descriptionLabel.widthAnchor.constraint(equalToConstant: 220.0),
            
            emailTextField.leadingAnchor.constraint(equalTo: logInStackView.leadingAnchor, constant: 5.0),
            emailTextField.trailingAnchor.constraint(equalTo: logInStackView.trailingAnchor),
            emailTextField.topAnchor.constraint(equalTo: logInStackView.topAnchor),
            emailTextField.heightAnchor.constraint(equalToConstant: 50.0),
            
            passwordTextField.leadingAnchor.constraint(equalTo: logInStackView.leadingAnchor, constant: 5.0),
            passwordTextField.trailingAnchor.constraint(equalTo: logInStackView.trailingAnchor),
            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50.0),
            
            logInStackView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 35.0),
            logInStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16.0),
            logInStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16.0),
            logInStackView.heightAnchor.constraint(equalToConstant: 100.0),
            
            divider.topAnchor.constraint(equalTo: logInStackView.topAnchor, constant: 50.0),
            divider.leadingAnchor.constraint(equalTo: logInStackView.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: logInStackView.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 0.5),
            
            loginButton.topAnchor.constraint(equalTo: logInStackView.bottomAnchor, constant: 16.0),
            loginButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16.0),
            loginButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16.0),
            loginButton.heightAnchor.constraint(equalToConstant: 50.0),
            
            loginByPhoneTextButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 16.0),
            loginByPhoneTextButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loginByPhoneTextButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16.0)
        ])
    }
  
    private func setupLoginButton() {
       loginButton.setAction { [weak self] in
           self?.didTapLoginButton()
       }
    }
    
    private func bindViewModel() {
        viewModel.isLoading.binding { [weak self] isLoading in
            guard let self else { return }
            self.loginButton.isLoading = isLoading
            self.updateStateLoginButton(isLoading: isLoading)
        }

        viewModel.errorText.binding { [weak self] text in
            guard let self, let text, !text.isEmpty else { return }
            self.showAlert(message: text)
        }
        
        viewModel.onSuccess = { [weak self] user in
            self?.coordinator?.didLogin(user: user)
        }
    }
    
    private func autofill() {
           #if DEBUG
           emailTextField.text = "developer@test.ru"
           passwordTextField.text = "qwe123!"
           #endif
       }
       
       private func updateStateLoginButton(isLoading: Bool? = nil) {
           let email = (emailTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
           let password = passwordTextField.text ?? ""
           
           let hasEmail = !email.isEmpty
           let hasPassword = !password.isEmpty
           let isLoadingNow = isLoading ?? viewModel.isLoading.value
           
           loginButton.isEnabled = hasEmail && hasPassword && !isLoadingNow
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
       
       @objc private func didTapLoginButton() {
           viewModel.email = emailTextField.text ?? ""
           viewModel.password = passwordTextField.text ?? ""
           viewModel.login()
       }
       
       @objc private func didTapLoginByPhone() {
           coordinator?.present(.phoneLogin)
       }
       
       @objc private func textFieldsDidChange(_ textField: UITextField) {
           updateStateLoginButton()
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

