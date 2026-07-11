import UIKit

/// Экран редактирования данных профиля.
@MainActor
final class ProfileEditViewController: BaseScrollViewController {

    private let viewModel: ProfileEditViewModel

    private lazy var firstNameField = LabeledTextFieldView(
        title: "Имя",
        placeholder: "Имя"
    )

    private lazy var lastNameField = LabeledTextFieldView(
        title: "Фамилия",
        placeholder: "Фамилия"
    )

    private lazy var nicknameField = LabeledTextFieldView(
        title: "Никнейм",
        placeholder: "Введите ник"
    )

    private lazy var cityField = LabeledTextFieldView(
        title: "Город",
        placeholder: "Город"
    )

    /// Поле для даты рождения с `UIDatePicker` как inputView.
    private lazy var birthDateField: LabeledTextFieldView = {
        let field = LabeledTextFieldView(
            title: "Дата рождения",
            placeholder: "дд.MM.гггг"
        )
        field.textField.inputView = birthDatePicker
        field.textField.tintColor = .clear
        field.textField.delegate = self
        return field
    }()

    private lazy var statusField = LabeledTextFieldView(
        title: "Статус",
        placeholder: "Что нового?"
    )


    private lazy var aboutTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "О себе"
        label.font = UIFont.preferredFont(forTextStyle: .footnote).withSize(14)
        label.textColor = .appPrimaryText
    //    label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()

    /// Многострочное поле "О себе".
    private lazy var aboutTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = .appTextFieldBackground
        textView.textColor = .appPrimaryText
        textView.layer.cornerRadius = 10
        textView.isScrollEnabled = false
        textView.returnKeyType = .default
        textView.heightAnchor.constraint(equalToConstant: 200.0).isActive = true
    //    textView.translatesAutoresizingMaskIntoConstraints = false
        
        return textView
    }()

    /// Общий стек для заголовка "О себе" и текст‑вью.
    private lazy var aboutStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [aboutTitleLabel, aboutTextView])
        stack.axis = .vertical
        stack.spacing = 4
     //   stack.translatesAutoresizingMaskIntoConstraints = false
        
        return stack
    }()

    /// Пикер даты, который используется как `inputView` для `birthDateField`.
    private lazy var birthDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.maximumDate = Date()
        picker.addTarget(self, action: #selector(birthDateChanged), for: .valueChanged)
        
        return picker
    }()

    /// Главный вертикальный стек со всеми полями.
    private lazy var mainStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            firstNameField,
            lastNameField,
            nicknameField,
            cityField,
            birthDateField,
            statusField,
            aboutStack
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        return stack
    }()

    /// Прозрачный фон под кнопкой OK.
    private lazy var aboutAccessoryBackground: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()

    /// Кнопка "OK" в accessory‑pane для закрытия клавиатуры в блоке "О себе".
    private lazy var aboutOkButton: PrimaryActionButton = {
        let button = PrimaryActionButton(title: "OK")
        button.setAction { [weak self] in
            self?.view.endEditing(true)
        }
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    /// Полупрозрачный оверлей для блокировки UI во время сохранения.
    private lazy var loadingOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        
        return view
    }()

    /// Активити индикатор по центру экрана.
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .appAccent
        indicator.translatesAutoresizingMaskIntoConstraints = false
        
        return indicator
    }()

    init(viewModel: ProfileEditViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Редактирование"
        view.backgroundColor = .appBackground
        
        setupNavBar()
        setupAboutAccessoryView()
        configureTextFields()
        applyInitialValues()
        bindViewModel()
        setupLoadingOverlay()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        rootTabContainerController?.setTabBarHidden(true, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        rootTabContainerController?.setTabBarHidden(false, animated: true)
    }

    override func configureContent() {
        super.configureContent()
        contentView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupLoadingOverlay() {
        view.addSubview(loadingOverlay)
        loadingOverlay.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            loadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: loadingOverlay.centerYAnchor)
        ])
    }

    /// Настройка accessory‑view с кнопкой "OK" для блока "О себе".
    private func setupAboutAccessoryView() {
        let height: CGFloat = 52
        let container = UIView(frame: CGRect(
            x: 0,
            y: 0,
            width: view.bounds.width,
            height: height
        ))
        container.backgroundColor = .clear
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        container.addSubview(aboutAccessoryBackground)
        aboutAccessoryBackground.addSubview(aboutOkButton)

        NSLayoutConstraint.activate([
            aboutAccessoryBackground.topAnchor.constraint(equalTo: container.topAnchor),
            aboutAccessoryBackground.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            aboutAccessoryBackground.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            aboutAccessoryBackground.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            aboutOkButton.trailingAnchor.constraint(equalTo: aboutAccessoryBackground.trailingAnchor, constant: -12),
            aboutOkButton.centerYAnchor.constraint(equalTo: aboutAccessoryBackground.centerYAnchor),
            aboutOkButton.heightAnchor.constraint(equalToConstant: 40),
            aboutOkButton.widthAnchor.constraint(equalToConstant: 60)
        ])

        aboutTextView.inputAccessoryView = container
    }

    /// Кнопка "Готово" в навбаре, триггерит `viewModel.didTapSave()`.
    private func setupNavBar() {
        let doneItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(saveTapped)
        )
        doneItem.tintColor = .app
        navigationItem.rightBarButtonItem = doneItem
    }

    /// Заполняет UI текущими данными пользователя из ViewModel.
    private func applyInitialValues() {
        firstNameField.textField.text = viewModel.firstName
        lastNameField.textField.text = viewModel.lastName
        nicknameField.textField.text = viewModel.nickname
        cityField.textField.text = viewModel.city
        statusField.textField.text = viewModel.status
        aboutTextView.text = viewModel.about

        if let date = viewModel.birthDate {
            birthDatePicker.date = date
            birthDateField.textField.text = format(date: date)
        }
    }

    /// Делегаты и returnKey для текстовых полей.
    private func configureTextFields() {
        [firstNameField, lastNameField, nicknameField, cityField, statusField].forEach {
            $0.textField.delegate = self
            $0.textField.returnKeyType = .done
        }
    }

    private func bindViewModel() {
        viewModel.onLoadingChange = { [weak self] isLoading in
            self?.setLoading(isLoading)
        }

        viewModel.onError = { [weak self] error in
            self?.setLoading(false)
            self?.showAlert(message: error.localizedDescription)
        }
    }

    /// Форматирование даты рождения для отображения в текстовом поле.
    private func format(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
    
    /// Показ/скрытие оверлея загрузки и блокировка UI.
    private func setLoading(_ isLoading: Bool) {
        if isLoading {
            view.endEditing(true)
            loadingOverlay.isHidden = false
            activityIndicator.startAnimating()
            view.isUserInteractionEnabled = false
        } else {
            loadingOverlay.isHidden = true
            activityIndicator.stopAnimating()
            view.isUserInteractionEnabled = true
        }
    }
    
    /// Собирает значения из UI в ViewModel и дергает `didTapSave()`.
    @objc private func saveTapped() {
        viewModel.firstName = firstNameField.textField.text ?? ""
        viewModel.lastName = lastNameField.textField.text ?? ""
        viewModel.nickname = nicknameField.textField.text ?? ""
        viewModel.city = cityField.textField.text ?? ""
        viewModel.status = statusField.textField.text ?? ""
        viewModel.about = aboutTextView.text ?? ""
        viewModel.birthDate = birthDatePicker.date

        viewModel.didTapSave()
    }

    @objc private func birthDateChanged() {
        let date = birthDatePicker.date
        viewModel.birthDate = date
        birthDateField.textField.text = format(date: date)
    }
}

// MARK: - UITextFieldDelegate

extension ProfileEditViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
