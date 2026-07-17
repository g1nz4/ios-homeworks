import UIKit

/// Ячейка профиля с аватаркой, именем и кликабельной надписью "Редактировать профиль".
final class ProfileCell: UICollectionViewCell {
   
    static let reuseId = "ProfileCell"
    
    /// Колбэк, который вызывается при тапе по надписи "Редактировать профиль"
    var onEditTap: (() -> Void)?

    /// Таск загрузки аватарки.
    private var imageTask: Task<Void, Never>?

    /// Аватар пользователя
    private lazy var avatarView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 25
        imageView.layer.borderWidth = 0.2
        imageView.layer.borderColor = UIColor.appPrimaryText.cgColor
        imageView.backgroundColor = .systemGray5
        
        return imageView
    }()

    /// Имя пользователя
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        
        return label
    }()

    /// Кликабельный label "Редактировать профиль"
    private lazy var editLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .appAccent
        label.text = "Редактировать профиль"
        label.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(editTapped))
        label.addGestureRecognizer(tap)
        
        return label
    }()

    /// Вертикальный стек: [имя, "Редактировать профиль"]
    private lazy var vStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nameLabel, editLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Перед повторным использованием ячейки отменить загрузку картинки и сбрасить изображение
    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        avatarView.image = nil
    }

    /// Верстка и базовая настройка UI
    private func configureUI() {
        contentView.backgroundColor = .appBackground
        [avatarView, vStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
    
        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            avatarView.widthAnchor.constraint(equalToConstant: 50),
            avatarView.heightAnchor.constraint(equalTo: avatarView.widthAnchor),
            avatarView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),

            vStack.topAnchor.constraint(equalTo: avatarView.topAnchor, constant: 2),
            vStack.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            vStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    func configure(userDisplayName: String, userAvatarURL: String) {
        nameLabel.text = userDisplayName

        imageTask?.cancel()
        imageTask = avatarView.setImage(from: userAvatarURL, placeholder: nil)
    }
    
    /// Обработчик тапа по "Редактировать профиль"
    @objc private func editTapped() {
        onEditTap?()
    }
}
