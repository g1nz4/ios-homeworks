import UIKit

/// Вью для футера экрана настроек.
final class NotificationsFooterView: UIView {
    
    /// Паблик‑колбэк, который дергает контроллер.
    var onTap: (() -> Void)?
    
    /// Основной текст с пояснением.
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        
        return label
    }()
    
    /// Кнопка‑ссылка ("Открыть настройки").
    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        button.setTitleColor(tintColor, for: .normal)
        button.addTarget(
            self,
            action: #selector(handleTap),
            for: .touchUpInside
        )
        return button
    }()
    
    /// Вертикальный стек, в котором лежат `descriptionLabel` и `actionButton`.
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            descriptionLabel,
            actionButton
        ])
        stack.axis = .vertical
        stack.spacing = 8
        
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
  
    /// Базовая конфигурация иерархии и лэйаута.
    private func configureUI() {
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    /// Конфигурирование содержимого футера.
    func configure(text: String, buttonTitle: String) {
        descriptionLabel.text = text
        actionButton.setTitle(buttonTitle, for: .normal)
        actionButton.isHidden = buttonTitle.isEmpty
    }
    
    /// Обработчик нажатия на кнопку.  Вызывает публичный колбэк `onTap`.
    @objc private func handleTap() {
        onTap?()
    }
}
