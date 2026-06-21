import UIKit

/// Экран регистрации пользователя.
/// Собирает данные формы и передает их во ViewModel для валидации и отправки SMS-кода.
@MainActor
final class SignUpViewController: BaseScrollViewController {
    
    weak var coordinator: LoginCoordinator?
    
    private let viewModel: SignUpViewModel
    
    private lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .appSecondaryText
        label.font = .systemFont(ofSize: 14.0, weight: .medium)
        label.text = NSLocalizedString("signup_all_fields_required", comment: "Поясняющая строка: Все поля обязательны для заполнения")
        label.textAlignment = .left
        label.numberOfLines = 0
        
        return label
    }()
    
    private lazy var firstNameField = LabeledTextFieldView(
        title: NSLocalizedString("signup_first_name_title", comment: "ИМЯ"),
        placeholder: NSLocalizedString("signup_first_name_placeholder", comment: "Введите имя")
    )
    
    private lazy var lastNameField = LabeledTextFieldView(
        title: NSLocalizedString("signup_last_name_title", comment: "ФАМИЛИЯ"),
        placeholder: NSLocalizedString("signup_last_name_placeholder", comment: "Введите фамилию")
    )
    
    private lazy var birthDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.maximumDate = Date()
        picker.addTarget(self, action: #selector(birthDateChanged), for: .valueChanged)
        
        return picker
        
    }()
    
    private lazy var birthDateField: LabeledTextFieldView = {
        let field = LabeledTextFieldView(
            title: NSLocalizedString("signup_birthdate_title", comment: "ДАТА РОЖДЕНИЯ"),
            placeholder: NSLocalizedString("signup_birthdate_placeholder", comment: "дд.MM.гггг")
        )
        field.textField.inputView = birthDatePicker
        field.textField.tintColor = .clear
        
        return field
    }()
    
    private lazy var cityField = LabeledTextFieldView(
        title: NSLocalizedString("signup_city_title", comment: "ГОРОД"),
        placeholder: NSLocalizedString("signup_city_placeholder", comment: "Название города")
    )
    
    private lazy var phoneField = LabeledTextFieldView(
        title: NSLocalizedString("signup_phone_title", comment: "НОМЕР ТЕЛЕФОНА"),
        placeholder: "+7 (___) ___-__-__",
        keyboardType: .phonePad
    )
    
    private lazy var emailField = LabeledTextFieldView(
        title: NSLocalizedString("signup_email_title", comment: "АДРЕС ЭЛЕКТРОННОЙ ПОЧТЫ"),
        placeholder: NSLocalizedString("signup_email_placeholder", comment: "Введите email"),
        keyboardType: .emailAddress
    )
    
    private lazy var passwordField = LabeledTextFieldView(
        title: NSLocalizedString("signup_password_title", comment: "ПАРОЛЬ"),
        placeholder: NSLocalizedString("signup_password_placeholder", comment: "Минимум 6 символов"),
        isSecure: true
    )
    
    private lazy var repeatPasswordField = LabeledTextFieldView(
        title: NSLocalizedString("signup_repeat_password_title", comment: "ПОВТОР ПАРОЛЯ"),
        placeholder: NSLocalizedString("signup_repeat_password_placeholder", comment: "Еще раз пароль"),
        isSecure: true
    )
    
    private lazy var signUpButton = PrimaryActionButton(
        title: NSLocalizedString("signup_button_title", comment: "Кнопка зарегистрироваться")
    )
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            firstNameField,
            lastNameField,
            birthDateField,
            cityField,
            phoneField,
            emailField,
            passwordField,
            repeatPasswordField,
            label,
            signUpButton
        ])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12.0
        
        return stack
    }()
    
    
    init(viewModel: SignUpViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.isHidden = false
        self.title = NSLocalizedString("signup_screen_title", comment: "Название экрана в навигационном баре")
        view.backgroundColor = .appBackground
        
        setupTextFields()
        setupSignUpButton()
        bindViewModel()
    }
    
    override func configureContent() {
        contentView.addSubview(stackView)
        
        // По умолчанию кнопка недоступна, пока пользователь не заполнил все поля и не идёт загрузка
        signUpButton.isEnabled = false
        signUpButton.alpha = 0.7
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16.0),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16.0),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16.0),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16.0)
        ])
    }
    
    /// Настройка делегатов и обработчика изменения текста для всех текстовых полей формы.
    private func setupTextFields() {
        [firstNameField,
         lastNameField,
         birthDateField,
         cityField,
         phoneField,
         emailField,
         passwordField,
         repeatPasswordField].forEach { field in
            field.textField.delegate = self
            field.textField.addTarget(self, action: #selector(textFieldsDidChanged(_:)), for: .editingChanged)
        }
    }
    
    private func setupSignUpButton() {
        signUpButton.setAction { [weak self] in
            guard let self else { return }
            self.signUpTapped()
        }
    }
    
    private func bindViewModel() {
        // Ошибки валидации / сети
        viewModel.errorText.binding { [weak self] text in
            guard let self, let text, !text.isEmpty else { return }
            self.showAlert(message: text)
        }
        
        // Статус загрузки влияет на кнопку "Зарегистрироваться"
        viewModel.isLoading.binding { [weak self] isLoading in
            guard let self else { return }
            self.signUpButton.isLoading = isLoading
            self.updateStateSignUpButton(isLoading: isLoading)
        }
        
        // Успешная отправка SMS-кода — переход к экрану ввода кода
        viewModel.onSMSCodeSent = { [weak self] data, verificationID in
            self?.coordinator?.present(
                .phoneSignUpCode(
                    data: data,
                    verificationID: verificationID
                )
            )
        }
    }
    
    /// Пересчитывает, можно ли нажать кнопку "Зарегистрироваться".
    /// Кнопка активируется только если: все текстовые поля формы (имя, фамилия, дата рождения, город, телефон, email, пароли) непустые и сейчас не идёт сетевой запрос .
    private func updateStateSignUpButton(isLoading: Bool? = nil) {
        let fields: [UITextField] = [
            firstNameField.textField,
            lastNameField.textField,
            birthDateField.textField,
            cityField.textField,
            phoneField.textField,
            emailField.textField,
            passwordField.textField,
            repeatPasswordField.textField
        ]
        
        // Все поля должны быть непустыми (после trim пробелов с краёв)
        let allFilled = fields.allSatisfy { field in
            let text = field.text ?? ""
            return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        // Если явно не передано isLoading, берём текущее значение из viewModel
        let isLoadingNow = isLoading ?? viewModel.isLoading.value
        let canTap = allFilled && !isLoadingNow
        
        signUpButton.isEnabled = canTap
    }
    
    /// Любое изменение текста в полях пересчитывает состояние кнопки регистрации.
    @objc private func textFieldsDidChanged(_ textField: UITextField) {
        updateStateSignUpButton()
    }
    
    /// Нажатие на кнопку "Зарегистрироваться". Собирает данные формы, записывает во ViewModel и запускает сценарий регистрации.
    @objc private func signUpTapped() {
        view.endEditing(true)
        
        viewModel.firstName = firstNameField.textField.text ?? ""
        viewModel.lastName = lastNameField.textField.text ?? ""
        viewModel.city = cityField.textField.text ?? ""
        viewModel.email = emailField.textField.text ?? ""
        viewModel.password = passwordField.textField.text ?? ""
        viewModel.repeatPassword = repeatPasswordField.textField.text ?? ""
       
        Task { [weak self] in
            await self?.viewModel.signUp()
        }
    }
    
    /// Изменение даты рождения через UIDatePicker:  обновляет модель и отображает дату в поле в формате "дд.ММ.гггг".
    @objc private func birthDateChanged() {
        let date = birthDatePicker.date
        viewModel.birthDate = date
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        birthDateField.textField.text = formatter.string(from: date)
    }
}

extension SignUpViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(
        _ textField: UITextField
    ) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        // Маска для телефона, форматирование ввода в +7 (XXX) XXX-XX-XX
        guard textField === phoneField.textField else {
            return true
        }
        
        let currentText = textField.text ?? ""
        
        // Удаление символа
        if string.isEmpty {
            
            var digits = currentText.filter { $0.isNumber }
            // Убиратьпрефикс 7/8, если он попал в digits.
            if digits.hasPrefix("8") {
                digits.removeFirst()
            } else if digits.hasPrefix("7") {
                digits.removeFirst()
            }
            // Удалить последнюю цифру из оставшихся
            if !digits.isEmpty {
                digits.removeLast()
            }
            
            let formatted = PhoneFormatter.formatCleaned(digits)
            textField.text = formatted.formatted
            // plain: "+7" + 10 цифр для ViewModel/бэкенда
            viewModel.phone = formatted.plain
            
            return false
        }
        
        // Ввод / замена текста
        guard let textRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: textRange, with: string)
        
        let formatted = PhoneFormatter.format(updatedText)
        textField.text = formatted.formatted
        viewModel.phone = formatted.plain
        
        return false
    }
}
