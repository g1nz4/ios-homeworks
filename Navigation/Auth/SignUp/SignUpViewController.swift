import UIKit

final class SignUpViewController: UIViewController {

    weak var coordinator: LoginCoordinator?
    private var viewModel: SignUpViewModelProtocol

    private lazy var emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Введите еmail"
        textField.autocapitalizationType = .none
        textField.keyboardType = .emailAddress
        textField.borderStyle = .roundedRect
        textField.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        
        return textField
    }()

    private lazy var passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Пароль (минимум 6 символов)"
        textField.autocapitalizationType = .none
        textField.isSecureTextEntry = true
        textField.borderStyle = .roundedRect
        textField.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        
        return textField
    }()

    private lazy var repeatPasswordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Повторите пароль"
        textField.autocapitalizationType = .none
        textField.isSecureTextEntry = true
        textField.borderStyle = .roundedRect
        textField.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        
        return textField
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            emailTextField,
            passwordTextField,
            repeatPasswordTextField,
            signUpButton
        ])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12.0
        
        return stack
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
        button.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        button.addTarget(self, action: #selector(signUpTapped), for: .touchUpInside)
        
        return button
    }()

    init(delegate: LogInViewControllerDelegate) {
        self.viewModel = SignUpViewModel(signUpDelegate: delegate)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Регистрация"
        view.backgroundColor = .systemBackground
        setupUI()
        bindingViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false
    }

    private func setupUI() {
        view.addSubview(stackView)
        
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16.0),
            stackView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16.0),
            stackView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 20.0)
        ])
    }
    
    private func bindingViewModel() {
        viewModel.errorText.binding { [weak self] text in
            guard let text, !text.isEmpty else { return }
            DispatchQueue.main.async {
                self?.showAlert(message: text)
            }
        }
        
        viewModel.onSuccess = { [weak self] in
            self?.coordinator?.popToRoot()
        }
    }

    @objc private func signUpTapped() {
        viewModel.email = (emailTextField.text ?? "")
        viewModel.password = passwordTextField.text ?? ""
        viewModel.repeatPassword = repeatPasswordTextField.text ?? ""
        viewModel.signUp()
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: message,
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
