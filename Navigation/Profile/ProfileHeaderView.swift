import UIKit

/// Хедер профиля.  Содержит: обложку (cover); аватар, частично перекрывающий обложку; индикатор онлайн‑статуса; имя, статус / город;  кнопку "Подробная информация";
final class ProfileHeaderView: UICollectionReusableView {
    
    static let reuseId = "ProfileHeaderView"
    
    /// Тап по "Подробная информация".
    var onTapMore: (() -> Void)?
    /// Тап по аватару, если есть сториc.
    var onTapStory: (() -> Void)?
    /// Тап по аватару, если сториc нет.
    var onTapAvatar: (() -> Void)?
    
    /// Флаг наличия сториc у пользователя (влияет на бордер колор аватара и поведение тапа).
    private var hasStory: Bool = false
    /// Базовая высота обложки без оверскролла.
    private let coverHeight: CGFloat = 105.0
    /// Размер аватарки (ширина/высота).
    private let avatarSize: CGFloat = 120.0
    private let overScrollExtra: CGFloat = 80.0
    
    private var coverTopConstraint: NSLayoutConstraint!
    private var coverHeightConstraint: NSLayoutConstraint!
    /// Кэш последнего URL аватара, чтобы не грузить повторно.
    private var currentAvatarURL: URL?
    /// Кэш последнего URL обложки.
    private var currentCoverURL: URL?
    
    
    /// Обложка — тянется на всю ширину сверху, обрезается по краям.
    private lazy var coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        
        return imageView
    }()
    
    /// Нижний контейнер с основным контентом (аватар, имя, статус/город, кнопка инфо).
    private lazy var infoContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .appBackground
        view.layer.cornerRadius = 22
        view.clipsToBounds = false

        return view
    }()
    
    /// Аватарка - выступает наполовину вверх над infoContainer.
    private var avatarImageView: UIImageView = {
        let avatar = UIImageView()
        avatar.layer.borderWidth = 3.5
        avatar.layer.cornerRadius = 60.0
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.isUserInteractionEnabled = true
        
        return avatar
    }()
    
    /// Индикатор онлайна — маленький кружок внизу/справа от аватара.
    private let onlineIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGreen
        view.isHidden = false
        view.layer.cornerRadius = 8.0
        
        return view
    }()
    
    /// Имя пользователя.
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .appPrimaryText
        label.font = .systemFont(ofSize: 22.0, weight: .bold)
        label.textAlignment = .center
        
        return label
    }()
    
    /// Статус или город (тонкий текст под именем).
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14.0, weight: .regular)
        label.textColor = .appPrimaryText
        label.textAlignment = .center
        label.numberOfLines = 2
        
        return label
    }()
    
    /// Иконка "i" в кружке слева от "Подробная информация"
    private lazy var infoIconView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(systemName: "info.circle")
        view.tintColor = .appAccent
        view.contentMode = .scaleAspectFit
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        return view
    }()
    
    /// Текстовая кнопка  "Подробная информация" — с жестом тап.
    private lazy var moreInfoLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14.0, weight: .regular)
        label.textColor = .appAccent
        label.text = "Подробная информация"
        label.textAlignment = .center
        
        return label
    }()
    
    /// Горизонтальный стек: [иконка] [Подробная информация]
    private lazy var moreInfoStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [infoIconView, moreInfoLabel])
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        stack.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapMore))
        stack.addGestureRecognizer(tap)
        
        return stack
    }()
    
    /// Вертикальный стек: [имя] [статус/город] [Подробная информация].
    private lazy var stack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nameLabel, statusLabel, moreInfoStack])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center
        stack.distribution = .fillProportionally
        
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureUI()
        updateBorderColorsForCurrentTheme()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Обновить цвета бордеров, когда меняется тема
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        updateBorderColorsForCurrentTheme()
        
    }
    
    private func configureUI() {
        backgroundColor = .appSecondaryBackground
        
        [coverImageView, infoContainer].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        [avatarImageView, onlineIndicator, stack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            infoContainer.addSubview($0)
        }
        
        coverTopConstraint = coverImageView.topAnchor.constraint(equalTo: topAnchor)
        coverHeightConstraint = coverImageView.heightAnchor.constraint(equalToConstant: coverHeight)
        
        NSLayoutConstraint.activate([
            coverTopConstraint,
            coverImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            
            coverImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            coverHeightConstraint,
            infoContainer.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: -25),
            infoContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            infoContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            infoContainer.heightAnchor.constraint(equalToConstant: 160.0),
            
            avatarImageView.widthAnchor.constraint(equalToConstant: avatarSize),
            avatarImageView.heightAnchor.constraint(equalToConstant: avatarSize),
            avatarImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: infoContainer.topAnchor),
            
            onlineIndicator.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor, constant: 42.0),
            onlineIndicator.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor, constant: 44.0),
            onlineIndicator.heightAnchor.constraint(equalToConstant: 16.0),
            onlineIndicator.widthAnchor.constraint(equalToConstant: 16.0),
            
            stack.topAnchor.constraint(equalTo: infoContainer.topAnchor, constant: 60.0),
            stack.leadingAnchor.constraint(equalTo: infoContainer.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: infoContainer.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: infoContainer.bottomAnchor, constant: -12.0)
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapAvatar))
        avatarImageView.addGestureRecognizer(tap)
    }
    
    func setTopInset(_ inset: CGFloat) {
        coverTopConstraint.constant = -inset
        coverHeightConstraint.constant = coverHeight + inset
        layoutIfNeeded()
    }
    
    
    func configureHeader(with user: User, imageLoader: ImageLoader = .shared) {
        nameLabel.text = user.name.displayName
        
        if let status = user.status, !status.isEmpty {
            statusLabel.isHidden = false
            statusLabel.text = status
        } else if let city = user.city, !city.isEmpty {
            statusLabel.isHidden = false
            statusLabel.text = city
        } else {
            statusLabel.isHidden = true
        }
        
        // Аватар
        if let avatarURL = user.avatarURL {
            if avatarURL != currentAvatarURL || avatarImageView.image == nil {
                currentAvatarURL = avatarURL
                Task { [weak self] in
                    guard let self else { return }
                    if let image = await imageLoader.loadImage(from: avatarURL) {
                        await MainActor.run {
                            self.avatarImageView.image = image
                        }
                    }
                }
            }
        } else if avatarImageView.image == nil {
            avatarImageView.image = UIImage(systemName: "person.crop.circle")
        }
        
        // Обложка
        if let coverURL = user.coverURL {
            if coverURL != currentCoverURL || coverImageView.image == nil {
                currentCoverURL = coverURL
                Task { [weak self] in
                    guard let self else { return }
                    if let image = await imageLoader.loadImage(from: coverURL) {
                        await MainActor.run {
                            self.coverImageView.image = image
                        }
                    }
                }
            }
        }
    }
    
    /// Устанавливат флаг наличия сториз (меняет бордер аватара и обработчик тапа).
    func setHasStory(_ value: Bool) {
        hasStory = value
        updateBorderColorsForCurrentTheme()
    }
    
    /// Обновляет цвет бордера аватара и индикатора в зависимости от темы и флага hasStory.
    private func updateBorderColorsForCurrentTheme() {
        let avatarBorderColor: UIColor = {
            if hasStory {
                return UIColor.appAccent
            } else {
                return UIColor { trait in
                    trait.userInterfaceStyle == .dark ? .black : .white
                }
            }
        }()
        
        let indicatorBorderColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? .black : .white
        }
        
        avatarImageView.layer.borderColor = avatarBorderColor.cgColor
        onlineIndicator.layer.borderColor = indicatorBorderColor.cgColor
    }
    
    /// Тап по "Подробная информация".
    @objc private func didTapMore() {
        onTapMore?()
    }
    
    /// Тап по аватару: если есть сториз - открыть сторис, иначе - октрывается фото вьювер с текущим фото пользователя..
    @objc private func didTapAvatar() {
        if hasStory {
            onTapStory?()
        } else {
            onTapAvatar?()
        }
    }
}
