import UIKit

/// Заголовок секции в коллекции.
final class MusicSectionHeaderView: UICollectionReusableView {

    static let reuseId = "MusicSectionHeaderView"

    /// Коллбэк на нажатие кнопки.
    var onTapAction: (() -> Void)?
    
    /// Заголовок секции.
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .appPrimaryText
        
        return label
    }()

    /// Кнопка действия (по умолчанию с иконкой "плюс").
    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(nil, for: .normal)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = .systemBlue
        button.addTarget(self, action: #selector(didTapAction), for: .touchUpInside)
        
        return button
    }()

    /// Горизонтальный стек для заголовка и кнопки.
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, actionButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(stackView)
   
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(title: String, showsPlus: Bool) {
        titleLabel.text = title
        actionButton.isHidden = !showsPlus
    }

    @objc private func didTapAction() {
        onTapAction?()
    }
}
