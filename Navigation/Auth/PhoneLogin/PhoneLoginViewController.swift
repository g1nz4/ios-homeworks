import UIKit

/// Экран авторизации по номеру телефона.
/// Состоит из двух состояний: 1) Ввод номера телефона и отправка кода 2) Ввод кода из SMS.
@MainActor
final class PhoneLoginViewController: BaseScrollViewController {
    
    weak var coordinator: LoginCoordinator?
    
    private let viewModel: PhoneLoginViewModel
    
    /// Количество символов кода (размер OTP).
    private let codeLength = 6
   
    /// Массив полей ввода для кода (6 по одному символу).
    private var codeFields: [UITextField] = []
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .appPrimaryText
        label.font = UIFont.systemFont(ofSize: 14.0, weight: .medium)
        label.textAlignment = .center
        
        return label
    }()
    
    /// Поле номера телефона с маской ввода.
    private lazy var phoneTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.keyboardType = .phonePad
        textField.layer.cornerRadius = 10.0
        textField.placeholder = "+7(___)___-__-__"
        textField.textColor = .appPrimaryText
        textField.backgroundColor = .appTextFieldBackground
        textField.font = .systemFont(ofSize: 18, weight: .medium)
        textField.delegate = self
       
        return textField
    }()
    
    /// Стек из 6 полей ввода одноразового кода.
    private lazy var codeStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 8.0
        
        return stack
    }()
    
    /// Лейбл, в котором отображается таймер повторной отправки кода. После истечения таймера превращается в «Запросить код» и кликабелен.
    private lazy var timerLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .appPrimaryText
        label.font = .systemFont(ofSize: 18.0, weight: .regular)
        label.text = nil
        label.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapTimerLabel))
        label.addGestureRecognizer(tap)
        label.isHidden = true
        
        return label
    }()
    
    /// Кнопка запроса кода для введенного номера.
    private lazy var sendCodeButton = PrimaryActionButton(
        title: NSLocalizedString("phone_login_send_code_button_title", comment: "Кнопка запросить код"
        )
    )
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.color = .appAccent
        
        return indicator
    }()
    
    init(viewModel: PhoneLoginViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .appBackground
        navigationController?.navigationBar.isHidden = true
        
        setupCodeFields()
        setupSendCodeButton()
        bindViewModel()
        autofillPhone()
        
        phoneTextField.becomeFirstResponder()
    }
    
    override func configureContent() {
        super.configureContent()
        
        [titleLabel,
         phoneTextField,
         sendCodeButton,
         codeStackView,
         timerLabel,
         activityIndicator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 332.0),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.widthAnchor.constraint(equalToConstant: 220.0),
            
            phoneTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 35.0),
            phoneTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16.0),
            phoneTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16.0),
            phoneTextField.heightAnchor.constraint(equalToConstant: 50.0),
            
            sendCodeButton.topAnchor.constraint(equalTo: phoneTextField.bottomAnchor, constant: 16.0),
            sendCodeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16.0),
            sendCodeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16.0),
            sendCodeButton.heightAnchor.constraint(equalToConstant: 50.0),
            
            codeStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 35.0),
            codeStackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            codeStackView.widthAnchor.constraint(equalToConstant: 260.0),
            codeStackView.heightAnchor.constraint(equalToConstant: 50.0),
            
            timerLabel.topAnchor.constraint(equalTo: codeStackView.bottomAnchor, constant: 16.0),
            timerLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            timerLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -100.0),
            
            activityIndicator.centerXAnchor.constraint(equalTo: codeStackView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: codeStackView.centerYAnchor)
        ])
    }
    
    /// Создаёт 6 полей ввода для одноразового кода и добавляет их в стек.
    private func setupCodeFields() {
        for index in 0..<codeLength {
            let textField = OTPTextField()
            textField.tag = index
            textField.layer.cornerRadius = 8.0
            textField.textAlignment = .center
            textField.keyboardType = .numberPad
            textField.borderStyle = .roundedRect
            textField.backgroundColor = .appTextFieldBackground
            textField.font = .systemFont(ofSize: 24.0, weight: .medium)
            textField.textColor = .appPrimaryText
            textField.delegate = self
            textField.otpDelegate = self
            textField.addTarget(
                self,
                action: #selector(codeFieldChanged(_ :)),
                for: .editingChanged
            )
            codeFields.append(textField)
            codeStackView.addArrangedSubview(textField)
        }
    }
    
    private func setupSendCodeButton() {
        sendCodeButton.setAction { [weak self] in
            self?.didTapSendCode()
        }
    }
    
    /// Обновляет доступность и внешний вид кнопки «Получить код» в зависимости от валидности номера телефона.
    private func updateSendCodeButton(isLoading: Bool? = nil) {
        let enabledByPhone = viewModel.isPhoneValid
        let isLoadingNow = isLoading ?? viewModel.isLoading.value
        sendCodeButton.isEnabled = enabledByPhone && !isLoadingNow
    }
    
    private func bindViewModel() {
        // Переключение между экранами: номер телефона / ввод кода
        viewModel.state.binding { [weak self] state in
            guard let self else { return }
            self.updateUI(for: state)
        }
        
        // Индикатор загрузки
        viewModel.isLoading.binding { [weak self] isLoading in
            guard let self else { return }
            
            self.sendCodeButton.isLoading = isLoading
            self.updateSendCodeButton(isLoading: isLoading)
            
            // Доп. логика на экране ввода кода
            switch self.viewModel.state.value {
            case .enterCode:
                if isLoading {
                    // Поля кода остаются, таймер скрывается, поверх стека показывается индикатор
                    self.timerLabel.isHidden = true
                    self.activityIndicator.isHidden = false
                    self.activityIndicator.startAnimating()
                } else {
                    // Проверка закончилась — индикатор скрывается
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    self.timerLabel.isHidden = (self.viewModel.secondsLeft.value == nil)
                }
            case .enterPhone:
                // На экране ввода телефона это все скрыто
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                self.timerLabel.isHidden = true
            }
        }
        
        // Ошибки авторизации/валидации
        viewModel.errorText.binding { [weak self] message in
            guard let self, let message, !message.isEmpty else { return }
            self.showAlert(message: message)
        }
        
        // Таймер до возможности повторной отправки кода
        viewModel.secondsLeft.binding { [weak self] seconds in
            guard let self else { return }
            
            guard let seconds = seconds else {
                self.timerLabel.text = nil
                return
            }
            
            if seconds > 0 {
                let minutes = seconds / 60
                let sec = seconds % 60
                self.timerLabel.text = String(format: "%02d:%02d", minutes, sec)
            } else {
                self.timerLabel.text = NSLocalizedString("phone_login_send_code_button_title", comment: "Текстовая кнопка повторного запроса кода")
            }
        }
        
        // Разрешение на повторную отправку кода
        viewModel.canResend.binding { [weak self] canResend in
            guard let self else { return }
            self.timerLabel.textColor = canResend ? .systemBlue : .appSecondaryText
            
        }
        
        // Успешная авторизация — передача пользователя координатору
        viewModel.onSuccess = { [weak self] user in
            self?.coordinator?.didLogin(user: user)
        }
    }
    
    /// Обновляет UI в зависимости от состояния флоу (номер / код).
    private func updateUI(for state: PhoneLoginViewModel.State) {
        switch state {
        case .enterPhone:
            titleLabel.text = NSLocalizedString("phone_login_form_description", comment: "Строка: Введите номер телефона")
            
            phoneTextField.isHidden = false
            sendCodeButton.isHidden = false
            
            codeStackView.isHidden = true
            timerLabel.isHidden = true
            
            codeFields.forEach { $0.text = "" }
            phoneTextField.becomeFirstResponder()
            
        case .enterCode:
            titleLabel.text = NSLocalizedString("enter_code_from_SMS", comment: "Строка: Введите код из SMS")
           
            phoneTextField.isHidden = true
            sendCodeButton.isHidden = true
            
            codeStackView.isHidden = false
            timerLabel.isHidden = false
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            
            codeFields.forEach { $0.text = "" }
            codeFields.first?.becomeFirstResponder()
        }
    }
    
    /// Автоподстановка тестового номера в DEBUG‑сборкe.
    private func autofillPhone() {
        #if DEBUG
        let phone = "+79109109101"
        let formatted = PhoneFormatter.format(phone)
        phoneTextField.text = formatted.formatted
        viewModel.phone = formatted.plain
        updateSendCodeButton()
        #endif
    }
    
    /// Собирает код из всех полей и отправляет его на верификацию.
    private func sendCodeComplete() {
        let code = codeFields.compactMap { $0.text }.joined()
        
        guard code.count == codeLength else { return }
        viewModel.code = code
        
        Task { [weak self] in
            await self?.viewModel.verify()
        }
    }
    
    /// Нажатие на кнопку «Получить код».
    @objc private func didTapSendCode() {
        Task { [weak self] in
            await self?.viewModel.sendCode()
        }
    }
    
    /// Нажатие по лейблу таймера (когда он показывает «Запросить код»).
    @objc private func didTapTimerLabel() {
        guard viewModel.canResend.value else { return }
        
        Task { [weak self] in
            await self?.viewModel.resendCode()
        }
    }
    
    /// Обработка ввода в поля кода — переключение фокуса между полями и авто‑отправка.
    @objc private func codeFieldChanged(_ textField: UITextField) {
        guard let text = textField.text else { return }
        // Один символ для каждого textField
        if text.count > 1 {
            textField.text = String(text.suffix(1))
        }
        // Переход к следующему полю или отправка кода
        if textField.text?.isEmpty == false {
            let nextIndex = textField.tag + 1
           
            if nextIndex < codeFields.count {
                codeFields[nextIndex].becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
                sendCodeComplete()
            }
        }
    }
}

extension PhoneLoginViewController: UITextFieldDelegate {
    
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        
        // Маска телефона
        if textField === phoneTextField {
            let currentText = textField.text ?? ""
            
            // Удаление символа
            if string.isEmpty {
                var digits = currentText.filter { $0.isNumber }
                // Убирать префикс 7/8, если есть
                if digits.hasPrefix("8") {
                    digits.removeFirst()
                } else if digits.hasPrefix("7") {
                    digits.removeFirst()
                }
                // Удалить последнюю цифру
                if !digits.isEmpty {
                    digits.removeLast()
                }
                
                let formatted = PhoneFormatter.formatCleaned(digits)
                textField.text = formatted.formatted
                viewModel.phone = formatted.plain
                updateSendCodeButton()
                return false
            }
            
            // Ввод цифры
            guard let textRange = Range(range, in: currentText) else { return false }
            let updatedText = currentText.replacingCharacters(in: textRange, with: string)
            
            let formatted = PhoneFormatter.format(updatedText)
            textField.text = formatted.formatted
            viewModel.phone = formatted.plain
            updateSendCodeButton()
            return false
        }
        
        // Поля одноразового кода
        let isCodeField = codeFields.contains { $0 === textField }
        guard isCodeField else { return true }
        
        // Backspace в полях кода обрабатывается в deleteBackward
        if string.isEmpty {
            return true
        }
        
        // Разрешить вводить только цифры
        let digitSet = CharacterSet.decimalDigits
        if !digitSet.isSuperset(of: CharacterSet(charactersIn: string)) {
            return false
        }
        
        // Максимум 1 символ в поле
        textField.text = string
        
        let nextIndex = textField.tag + 1
        if nextIndex < codeFields.count {
            codeFields[nextIndex].becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            sendCodeComplete()
        }
        
        return false
    }
}

extension PhoneLoginViewController: OTPTextFieldDelegate {
   
    func otpTextFieldDidDelete(_ textField: OTPTextField) {
        // Когда поле пустое и пользователь нажал Backspace
        let prevIndex = textField.tag - 1
        guard prevIndex >= 0 else { return }

        let prev = codeFields[prevIndex]
        prev.becomeFirstResponder()
        // сразу удалить цифру в предыдущем
        prev.text = ""
    }
}
