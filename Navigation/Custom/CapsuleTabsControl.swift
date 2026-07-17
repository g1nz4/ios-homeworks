import UIKit

/// Универсальный контрол табов с капсулой под выбранной кнопкой.
final class CapsuleTabsControl: UIView {

    /// Заголовки табов.
    var titles: [String] = [] {
        didSet { rebuildButtons() }
    }

    /// Текущий выбранный индекс (read‑only снаружи).
    private(set) var selectedIndex: Int = 0

    /// Колбэк при смене таба.
    var onSelectIndex: ((Int) -> Void)?

    private lazy var container: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        
        return view
    }()

    /// Капсула выбранной кнопки.
    private lazy var capsuleView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .appBackground
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.appSecondaryText.withAlphaComponent(0.2).cgColor
        view.layer.shadowColor = UIColor.appSecondaryText.withAlphaComponent(0.2).cgColor
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 4
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        
        return view
    }()

    /// Стек с кнопками табов.
    private lazy var stack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        
        return stack
    }()

    /// Кнопки табов в текущем контроле.
    private var buttons: [UIButton] = []

    /// Констрейнты, которые меняются при смене выбранного таба.
    private var capsuleLeadingConstraint: NSLayoutConstraint?
    private var capsuleTrailingConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
       configureUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureUI()
    }

    private func configureUI() {
        addSubview(container)
        container.addSubview(capsuleView)
        container.addSubview(stack)
        
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),

            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            capsuleView.topAnchor.constraint(equalTo: container.topAnchor),
            capsuleView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    /// Выбирает таб по индексу.
    func setSelectedIndex(_ index: Int, animated: Bool) {
        guard index >= 0, index < buttons.count else { return }
        selectedIndex = index

        for (i, button) in buttons.enumerated() {
            button.isSelected = (i == index)
        }

        moveCapsule(to: buttons[index], animated: animated)
    }
    
    /// Пересоздаёт кнопки по текущему массиву `titles`.
    private func rebuildButtons() {
        // Удалить старые arrangedSubviews
        for view in stack.arrangedSubviews {
            stack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        buttons.removeAll()

        // Создать новые
        for (index, title) in titles.enumerated() {
            let button = makeButton(title: title, index: index)
            buttons.append(button)
            stack.addArrangedSubview(button)
        }

        // Сбросить констрейнты капсулы
        capsuleLeadingConstraint?.isActive = false
        capsuleTrailingConstraint?.isActive = false
        capsuleLeadingConstraint = nil
        capsuleTrailingConstraint = nil

        // Если табы есть — выставить выбранный или 0
        guard !buttons.isEmpty else { return }

        let clampedIndex = min(selectedIndex, buttons.count - 1)
        selectedIndex = clampedIndex

        for (i, button) in buttons.enumerated() {
            button.isSelected = (i == clampedIndex)
        }

        // После первого layout’а позициониовать капсулу
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.moveCapsule(to: self.buttons[clampedIndex], animated: false)
        }
    }

    private func makeButton(title: String, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.tag = index
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        button.setTitleColor(.appSecondaryText, for: .normal)
        button.setTitleColor(.appAccent, for: .selected)

        button.backgroundColor = .clear
        button.tintColor = .clear
        button.setBackgroundImage(UIImage(), for: .normal)
        button.setBackgroundImage(UIImage(), for: .highlighted)
        button.setBackgroundImage(UIImage(), for: .selected)

        button.addTarget(self, action: #selector(handleTap(_:)), for: .touchUpInside)
        return button
    }

    /// Двигает капсулу под переданную кнопку.
    private func moveCapsule(to button: UIButton, animated: Bool) {
        // Отключить старые связи
        capsuleLeadingConstraint?.isActive = false
        capsuleTrailingConstraint?.isActive = false

        // Привязать капсулу к выбранной кнопке
        capsuleLeadingConstraint = capsuleView.leadingAnchor.constraint(equalTo: button.leadingAnchor)
        capsuleTrailingConstraint = capsuleView.trailingAnchor.constraint(equalTo: button.trailingAnchor)
        capsuleLeadingConstraint?.isActive = true
        capsuleTrailingConstraint?.isActive = true

        let animations = {
            self.layoutIfNeeded()
        }

        if animated {
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                usingSpringWithDamping: 0.9,
                initialSpringVelocity: 0.2,
                options: [.curveEaseInOut, .allowUserInteraction],
                animations: animations,
                completion: nil
            )
        } else {
            animations()
        }
    }
    
    @objc private func handleTap(_ sender: UIButton) {
        let index = sender.tag
        guard index != selectedIndex else { return }
        
        setSelectedIndex(index, animated: true)
        onSelectIndex?(index)
    }
}
