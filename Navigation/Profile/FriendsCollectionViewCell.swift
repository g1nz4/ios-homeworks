import UIKit

/// Ячейка блока "Друзья" в профиле. Показывает заголовок, количество друзей и три аватара друзей.
final class FriendsCollectionViewCell: UICollectionViewCell {

    static let reuseId = "FriendsCollectionViewCell"

    /// Фоновая капсула.
    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .appBackground
        view.layer.cornerRadius = 18
        view.clipsToBounds = true
        
        return view
    }()

    /// Заголовок блока.
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Друзья"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .appPrimaryText
        
        return label
    }()

    /// Количество друзей.
    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        
        return label
    }()

    /// Горизонтальный стек для аватарок друзей. Отрицательный spacing для эффекта наложения аватарок.
    private lazy var avatarsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = -8
        stack.alignment = .center
        
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        contentView.backgroundColor = .clear
        contentView.addSubview(containerView)
       
        [titleLabel, countLabel, avatarsStackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview($0)
        }
    
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            countLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 4),
            countLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

            avatarsStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            avatarsStackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            avatarsStackView.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    func configure(friendsCount: Int) {
        countLabel.text = "\(friendsCount)"
        avatarsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Сейчас — заглушки из ассетов: friend1, friend2, friend3.
        // В будущем реальные URL и загрузка картинок через ImageLoader.
        for index in 0..<3 {
            let imageView = makeAvatarImageView()
            imageView.image = UIImage(named: "friend\(index + 1)")
            avatarsStackView.addArrangedSubview(imageView)
        }
    }

    /// Создаёт настроенный UIImageView для аватарки друга.
    private func makeAvatarImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 28),
            imageView.heightAnchor.constraint(equalToConstant: 28)
        ])

        imageView.layer.cornerRadius = 14
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .tertiarySystemFill // фон‑заглушка

        return imageView
    }
}
