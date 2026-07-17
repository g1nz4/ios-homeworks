import UIKit

/// Плавающая капсула с заголовком и стрелкой. Используется как кнопка для перехода в раздел.
final class FloatingCapsuleButton: UIControl {

    /// Фоновый контейнер с закруглениями, границей и тенью.
    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .appBackground
        view.layer.cornerRadius = 18
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.appSecondaryText.cgColor
        view.layer.shadowColor = UIColor.appPrimaryText.cgColor
        view.layer.shadowOpacity = 0.18
        view.layer.shadowRadius = 8
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.isUserInteractionEnabled = false
        
        return view
    }()

    /// Заголовок на капсуле.
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .appPrimaryText
        
        return label
    }()

    /// Chevron справа.
    private lazy var chevron: UIImageView = {
        let view = UIImageView(image: UIImage(systemName: "chevron.right"))
        view.tintColor = .appPrimaryText
        view.contentMode = .scaleAspectFit
        
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        isUserInteractionEnabled = true
        backgroundColor = .clear
        addSubview(containerView)

        [titleLabel, chevron].forEach {
            containerView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            chevron.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 4),
            chevron.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            chevron.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 10),
            chevron.heightAnchor.constraint(equalToConstant: 14)
        ])
    }

    func configure(title: String) {
        titleLabel.text = title
    }
}
