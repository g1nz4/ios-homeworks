import UIKit

/// Нижний лист с подробной информацией о пользователе. Появляется поверх текущего экрана с затемнением фона.
final class ProfileInfoViewController: UIViewController {

    private let viewModel: ProfileInfoViewModel

    /// Полупрозрачный тёмный фон за шторкой.
    private lazy var dimmingView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        view.alpha = 0

        // Тап по затемнению закрывает шторку
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapClose))
        view.addGestureRecognizer(tap)

        return view
    }()

    /// Основной контейнер шторки (нижний sheet).
    private lazy var sheetView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .appBackground
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.masksToBounds = true

        // Жест вниз для закрытия шторки
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)

        return view
    }()

    /// Внутренний контейнер контента шторки (для отступов от краёв).
    private lazy var contentContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()

    /// Главный вертикальный стек всего содержания.
    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        
        return stack
    }()

    /// Нижний констрейнт шторки, для показа/скрытия.
    private var sheetBottomConstraint: NSLayoutConstraint!

    /// Флаг, чтобы анимация появления запускалась только один раз.
    private var didAnimatePresent = false

    init(viewModel: ProfileInfoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        setupHierarchy()
        setupConstraints()
        configureContent()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animatePresentIfNeeded()
    }

    /// Настройка иерархии вью.
    private func setupHierarchy() {
        // Затемнение на весь экран
        view.addSubview(dimmingView)
        // Шторка поверх dimmingView
        view.addSubview(sheetView)
        // Контентный контейнер внутри шторки
        sheetView.addSubview(contentContainerView)
        // Главный стек внутри контейнера
        contentContainerView.addSubview(contentStackView)
    }

    /// Настройка констрейнтов всех основных вью.
    private func setupConstraints() {
        // Стартовая позиция шторки - ниже экрана, для анимации появления
        sheetBottomConstraint = sheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 400)

        NSLayoutConstraint.activate([
            // Dimming — на весь экран
            dimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            sheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheetBottomConstraint,
            // Минимальная высота шторки ~45% высоты экрана
            sheetView.heightAnchor.constraint(greaterThanOrEqualTo: view.heightAnchor, multiplier: 0.45),

            // Контейнер контента внутри шторки
            contentContainerView.topAnchor.constraint(equalTo: sheetView.safeAreaLayoutGuide.topAnchor, constant: 16),
            contentContainerView.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 16),
            contentContainerView.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -16),
            contentContainerView.bottomAnchor.constraint(lessThanOrEqualTo: sheetView.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            // Главный стек в контейнере
            contentStackView.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentContainerView.bottomAnchor)
        ])
    }

    /// Наполнение стека контентом на основе данных ViewModel.
    private func configureContent() {
        let info = viewModel.data

        // Header через фабрику
        let header = ProfileInfoViewFactory.header { [weak self] in
            self?.didTapClose()
        }
        contentStackView.addArrangedSubview(header)
        contentStackView.addArrangedSubview(ProfileInfoViewFactory.separator())

        // Статус
        if let status = info.status, !status.isEmpty {
            contentStackView.addArrangedSubview(
                ProfileInfoViewFactory.row(icon: "bubble", text: status, tint: .secondaryLabel)
            )
        }

        // Ник
        if let nick = info.nickname, !nick.isEmpty {
            contentStackView.addArrangedSubview(
                ProfileInfoViewFactory.row(icon: "at", text: nick, tint: .secondaryLabel)
            )
        }

        // ДР
        if let birthday = info.birthday, !birthday.isEmpty {
            contentStackView.addArrangedSubview(
                ProfileInfoViewFactory.row(icon: "gift", text: "День рождения: \(birthday)")
            )
        }

        // Город
        if let city = info.city, !city.isEmpty {
            contentStackView.addArrangedSubview(
                ProfileInfoViewFactory.row(icon: "house", text: "Город: \(city)")
            )
        }

        // Подписчики
        if let subs = info.subscribersCount {
            contentStackView.addArrangedSubview(
                ProfileInfoViewFactory.row(icon: "dot.radiowaves.up.forward", text: subs)
            )
        }

        contentStackView.addArrangedSubview(ProfileInfoViewFactory.separator())

        // Друзья / подписки
        let friendsFollowingStack = UIStackView()
        friendsFollowingStack.axis = .vertical
        friendsFollowingStack.spacing = 8
        friendsFollowingStack.translatesAutoresizingMaskIntoConstraints = false

        if let friends = info.friendsCount {
            friendsFollowingStack.addArrangedSubview(
                ProfileInfoViewFactory.navigationRow(icon: "person", title: "Друзья", value: friends)
            )
        }

        if let following = info.followingCount {
            friendsFollowingStack.addArrangedSubview(
                ProfileInfoViewFactory.navigationRow(icon: "person.2", title: "Подписки", value: following)
            )
        }

        contentStackView.addArrangedSubview(friendsFollowingStack)

        // О себе
        if let about = info.about, !about.isEmpty {
            contentStackView.addArrangedSubview(ProfileInfoViewFactory.separator())

            let aboutContainer = UIStackView()
            aboutContainer.axis = .vertical
            aboutContainer.spacing = 8
            aboutContainer.translatesAutoresizingMaskIntoConstraints = false

            let sectionTitle = UILabel()
            sectionTitle.text = "Основная информация"
            sectionTitle.font = .systemFont(ofSize: 17, weight: .semibold)
            sectionTitle.textColor = .appPrimaryText

            let aboutTitle = UILabel()
            aboutTitle.text = "О себе"
            aboutTitle.font = .systemFont(ofSize: 13)
            aboutTitle.textColor = .appSecondaryText

            let aboutLabel = UILabel()
            aboutLabel.text = about
            aboutLabel.font = .systemFont(ofSize: 15)
            aboutLabel.textColor = .appPrimaryText
            aboutLabel.numberOfLines = 0

            aboutContainer.addArrangedSubview(sectionTitle)
            aboutContainer.addArrangedSubview(aboutTitle)
            aboutContainer.addArrangedSubview(aboutLabel)

            contentStackView.addArrangedSubview(aboutContainer)
        }
    }

    /// Запуск анимации появления.
    private func animatePresentIfNeeded() {
        guard !didAnimatePresent else { return }
        didAnimatePresent = true
        animatePresent()
    }

    /// Анимация выезда шторки снизу и появления затемнения.
    private func animatePresent() {
        view.layoutIfNeeded()
        sheetBottomConstraint.constant = 0

        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0.6,
            options: [.curveEaseOut]
        ) {
            self.dimmingView.alpha = 1
            self.view.layoutIfNeeded()
        }
    }

    /// Анимация скрытия шторки вниз и исчезновения затемнения.
    private func animateDismiss(completion: (() -> Void)? = nil) {
        sheetBottomConstraint.constant = 400

        UIView.animate(
            withDuration: 0.3,
            animations: {
                self.dimmingView.alpha = 0
                self.view.layoutIfNeeded()
            },
            completion: { _ in completion?() }
        )
    }

    /// Закрытие по тапу на крестик или фон.
    @objc private func didTapClose() {
        animateDismiss { [weak self] in
            self?.dismiss(animated: false)
        }
    }

    /// Обработка жеста свайпа шторки вниз.
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)

        switch gesture.state {
        case .changed:
            guard translation.y > 0 else { return }
            sheetBottomConstraint.constant = translation.y
            dimmingView.alpha = max(0, 1 - translation.y / 400)

        case .ended, .cancelled:
            if translation.y > 120 {
                animateDismiss { [weak self] in
                    self?.dismiss(animated: false)
                }
            } else {
                sheetBottomConstraint.constant = 0
                UIView.animate(withDuration: 0.2) {
                    self.dimmingView.alpha = 1
                    self.view.layoutIfNeeded()
                }
            }

        default:
            break
        }
    }
}
