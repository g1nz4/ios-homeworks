import UIKit

protocol PostCollectionViewCellDelegate: AnyObject {
    func postCellDidTapMore(_ cell: PostCollectionViewCell)
    func postCellDidTapLike(_ cell: PostCollectionViewCell)
    func postCellDidTapShare(_ cell: PostCollectionViewCell)
    func postCellDidTapImage(_ cell: PostCollectionViewCell)
}

@MainActor
final class PostCollectionViewCell: UICollectionViewCell {

    static let reuseId = "PostCollectionViewCell"

    weak var delegate: PostCollectionViewCellDelegate?

    private var avatarTask: Task<Void, Never>?
    private var mediaTask: Task<Void, Never>?

    private var isLikedState: Bool = false
    private var fullText: String = ""
    private var isExpanded: Bool = false
    private var moreRange: NSRange?

    // Констрейнты для переключения в зависимости от наличия текста/картинки
    private var mediaHeightConstraint: NSLayoutConstraint!
    private var likesTopToDescriptionConstraint: NSLayoutConstraint!
    private var likesTopToMediaOrDateConstraint: NSLayoutConstraint!
    private var contentTopToMediaConstraint: NSLayoutConstraint!
    private var contentTopToDateConstraint: NSLayoutConstraint!

    /// Корневой контейнер ячейки.
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .appBackground
        view.clipsToBounds = false
        
        return view
    }()

    /// Аватар автора.
    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 0.15
        imageView.layer.borderColor = UIColor.appPrimaryText.cgColor
        imageView.layer.cornerRadius = 20
        imageView.backgroundColor = .appSecondaryBackground
        
        return imageView
    }()

    /// Имя  автора.
    private lazy var authorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18.0, weight: .bold)
        label.textColor = .appPrimaryText
        label.numberOfLines = 1
        
        return label
    }()

    /// Дата публикации.
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .appSecondaryText
        
        return label
    }()

    /// Основное изображение поста.
    private lazy var mediaImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.isUserInteractionEnabled = true
        
        return imageView
    }()

    /// Большое сердце для анимации double‑tap лайка.
    private lazy var bigHeartImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "heart.fill"))
        imageView.tintColor = .systemRed
        imageView.contentMode = .scaleAspectFit
        imageView.alpha = 0
        imageView.layer.shadowColor = UIColor.red.cgColor
        imageView.layer.shadowOpacity = 0.5
        imageView.layer.shadowRadius = 14
        imageView.layer.shadowOffset = CGSize(width: 0, height: 7)
        
        return imageView
    }()

    /// Текст поста (с поддержкой "Показать ещё" / "Свернуть").
    private lazy var contentDescriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14.0, weight: .medium)
        label.textColor = .appPrimaryText
        label.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleLabelTap(_:)))
        label.addGestureRecognizer(tap)

        return label
    }()

    /// Иконка лайка.
    private lazy var likesImage: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(systemName: "heart")
        image.tintColor = .systemRed
        image.contentMode = .scaleAspectFit
        
        return image
    }()

    /// Количество лайков.
    private lazy var likesLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14.0, weight: .semibold)
        label.textColor = .appPrimaryText
        
        return label
    }()

    /// Иконка просмотров.
    private lazy var viewsImage: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(systemName: "eye")
        image.tintColor = .appPrimaryText
        image.contentMode = .scaleAspectFit
        
        return image
    }()

    /// Количество просмотров.
    private lazy var viewsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14.0, weight: .semibold)
        label.textColor = .appPrimaryText
        
        return label
    }()

    /// Кнопка «Поделиться».
    private lazy var shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrowshape.turn.up.right"), for: .normal)
        button.tintColor = .appPrimaryText
       
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        
        return button
    }()

    /// Кнопка меню.
    private lazy var moreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        button.tintColor = .appSecondaryText
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.showsMenuAsPrimaryAction = true
        
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureUI()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        delegate = nil
        
        avatarTask?.cancel()
        avatarTask = nil
        avatarImageView.image = nil
        
        mediaTask?.cancel()
        mediaTask = nil
        mediaImageView.image = nil

        fullText = ""
        isExpanded = false
        moreRange = nil
        contentDescriptionLabel.attributedText = nil
    }

    private func configureUI() {
        contentView.clipsToBounds = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)

        [avatarImageView,
        authorLabel,
        dateLabel,
        mediaImageView,
        contentDescriptionLabel,
        likesImage,
        likesLabel,
        viewsImage,
        viewsLabel,
        shareButton,
        moreButton,
        bigHeartImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview($0)
        }
    
        mediaHeightConstraint = mediaImageView.heightAnchor.constraint(equalToConstant: 400)

        // top для description
        contentTopToMediaConstraint = contentDescriptionLabel.topAnchor.constraint(equalTo: mediaImageView.bottomAnchor, constant: 8)
        contentTopToDateConstraint = contentDescriptionLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8)

        // top для лайков
        likesTopToDescriptionConstraint = likesImage.topAnchor.constraint(equalTo: contentDescriptionLabel.bottomAnchor, constant: 12)
        likesTopToMediaOrDateConstraint = likesImage.topAnchor.constraint(equalTo: mediaImageView.bottomAnchor, constant: 12)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            avatarImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            avatarImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),

            moreButton.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            moreButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            moreButton.widthAnchor.constraint(equalToConstant: 25),
            moreButton.heightAnchor.constraint(equalToConstant: 8),

            authorLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 8),
            authorLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8.0),
            authorLabel.trailingAnchor.constraint(equalTo: moreButton.leadingAnchor, constant: -8),

            dateLabel.leadingAnchor.constraint(equalTo: authorLabel.leadingAnchor),
            dateLabel.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 2),
            dateLabel.trailingAnchor.constraint(equalTo: authorLabel.trailingAnchor),

            mediaImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            mediaImageView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
            mediaImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            mediaHeightConstraint,

            contentDescriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            contentDescriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),

            bigHeartImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            bigHeartImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            bigHeartImageView.widthAnchor.constraint(equalToConstant: 70),
            bigHeartImageView.heightAnchor.constraint(equalToConstant: 70),

            likesImage.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            likesImage.widthAnchor.constraint(equalToConstant: 22),
            likesImage.heightAnchor.constraint(equalToConstant: 22),

            likesLabel.centerYAnchor.constraint(equalTo: likesImage.centerYAnchor),
            likesLabel.leadingAnchor.constraint(equalTo: likesImage.trailingAnchor, constant: 4),

            shareButton.centerYAnchor.constraint(equalTo: likesImage.centerYAnchor),
            shareButton.leadingAnchor.constraint(equalTo: likesLabel.trailingAnchor, constant: 16),
            shareButton.widthAnchor.constraint(equalToConstant: 22),
            shareButton.heightAnchor.constraint(equalToConstant: 20),

            viewsLabel.centerYAnchor.constraint(equalTo: likesImage.centerYAnchor),
            viewsLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),

            viewsImage.centerYAnchor.constraint(equalTo: likesImage.centerYAnchor),
            viewsImage.trailingAnchor.constraint(equalTo: viewsLabel.leadingAnchor, constant: -4),
            viewsImage.widthAnchor.constraint(equalToConstant: 25),
            viewsImage.heightAnchor.constraint(equalToConstant: 20),

            likesImage.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])

        // Базовое состояние
        contentTopToMediaConstraint.isActive = true
        likesTopToDescriptionConstraint.isActive = true
    }
    
    @MainActor
    func configure(with post: MyPost, user: User) {
        fullText = post.description.trimmingCharacters(in: .whitespacesAndNewlines)
        isExpanded = post.isExpanded

        authorLabel.text = post.author
        dateLabel.text = post.createdAt.formatted(date: .long, time: .shortened)
        viewsLabel.text = "\(post.views)"

        updateLikeState(isLiked: post.isLiked, likes: post.likes)

        let hasImage = (post.image != nil) ||
                       (post.imagePath != nil && !(post.imagePath?.isEmpty ?? true))
        let hasText = !fullText.isEmpty

        // Картинка (UIImage или imagePath)
        configureMedia(for: post)


        // Отступы для текста
        if hasImage {
            contentTopToDateConstraint.isActive = false
            contentTopToMediaConstraint.isActive = hasText   // текст под картинкой
        } else {
            contentTopToMediaConstraint.isActive = false
            contentTopToDateConstraint.isActive = hasText    // текст под датой
        }

        // Лайки: если есть текст — под текстом, если нет — под картинкой/датой
        likesTopToDescriptionConstraint.isActive = hasText
        likesTopToMediaOrDateConstraint.isActive = !hasText

        updateTextForCurrentState()

        setNeedsLayout()
        layoutIfNeeded()

        // Аватар
        configureAvatar(post: post, currentUser: user)
    }

    func configureMenu(
        isFavorite: Bool? = nil,
        favoriteTitle: String? = nil,
        favoriteAlwaysYellow: Bool = false,
        onFavorite: (() -> Void)? = nil,
        onEdit: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        var actions: [UIAction] = []

        if let onFavorite {
            let title = favoriteTitle
                ?? ((isFavorite ?? false) ? "Удалить из избранного" : "Добавить в избранное")

            let starIsFilled = isFavorite ?? true
            let starImageName = starIsFilled ? "star.fill" : "star"
            let tintColor: UIColor = favoriteAlwaysYellow
                ? .systemYellow
                : (starIsFilled ? .systemYellow : .label)

            let starImage = UIImage(systemName: starImageName)?
                .withTintColor(tintColor, renderingMode: .alwaysOriginal)

            let favoriteAction = UIAction(title: title, image: starImage) { _ in
                onFavorite()
            }
            actions.append(favoriteAction)
        }

        if let onEdit {
            let editAction = UIAction(
                title: "Редактировать",
                image: UIImage(systemName: "pencil")
            ) { _ in onEdit() }
            actions.append(editAction)
        }

        if let onDelete {
            let deleteAction = UIAction(
                title: "Удалить",
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { _ in onDelete() }
            actions.append(deleteAction)
        }

        moreButton.menu = UIMenu(children: actions)
    }
    
    func updateViewsCount(_ views: Int) {
        viewsLabel.text = "\(views)"
    }

    func setMoreButtonHidden(_ hidden: Bool) {
        moreButton.isHidden = hidden
        moreButton.isEnabled = !hidden
    }
    
    func setShareButtonHidden(_ hidden: Bool) {
        shareButton.isHidden = hidden
        shareButton.isEnabled = !hidden
    }

    func updateLikeState(isLiked: Bool, likes: Int) {
        isLikedState = isLiked
        likesLabel.text = "\(likes)"
        likesImage.image = UIImage(systemName: isLiked ? "heart.fill" : "heart")
        likesImage.tintColor = isLiked ? .systemRed : .appSecondaryText
    }

    /// Настройка всех жестов.
    private func setupGestures() {
        // Тап по лайку
        let likeTap = UITapGestureRecognizer(target: self, action: #selector(handleLikeTap))
        likesImage.isUserInteractionEnabled = true
        likesImage.addGestureRecognizer(likeTap)

        let likeTap2 = UITapGestureRecognizer(target: self, action: #selector(handleLikeTap))
        likesLabel.isUserInteractionEnabled = true
        likesLabel.addGestureRecognizer(likeTap2)

        // Double‑tap по всему посту
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        containerView.isUserInteractionEnabled = true
        containerView.addGestureRecognizer(doubleTap)
        
        shareButton.addTarget(self, action: #selector(handleShareTap), for: .touchUpInside)
        
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(handleImageTap))
        mediaImageView.addGestureRecognizer(imageTap)

        // чтобы single tap по тексту не съедал double‑tap
        if let labelTap = contentDescriptionLabel.gestureRecognizers?.first {
            labelTap.require(toFail: doubleTap)
        }
    }

    private func configureAvatar(post: MyPost, currentUser: User) {
        avatarTask?.cancel()
        avatarTask = nil

        let placeholder = UIImage(systemName: "person.crop.circle")

        if let path = post.authorAvatarPath, !path.isEmpty {
            avatarTask = avatarImageView.setImage(from: path, placeholder: placeholder)
            return
        }

        if post.authorId == currentUser.id, let url = currentUser.avatarURL {
            avatarTask = avatarImageView.setImage(from: url.absoluteString, placeholder: placeholder)
            return
        }

        avatarImageView.image = placeholder
    }
    
    private func configureMedia(for post: MyPost) {
        mediaTask?.cancel()
        mediaTask = nil

        if post.image == nil, (post.imagePath == nil || post.imagePath?.isEmpty == true) {
            mediaImageView.image = nil
            mediaImageView.isHidden = true
            mediaHeightConstraint.constant = 0
            return
        }

        mediaImageView.isHidden = false
        mediaHeightConstraint.constant = 400

        if let imageData = post.image {
            let image = UIImage(data: imageData)
            mediaImageView.image = image
            return
        }

        mediaTask = mediaImageView.setImage(from: post.imagePath, placeholder: nil)
    }

    /// Обновляет текст лейбла с учётом состояния (свернут/развернут)
    private func updateTextForCurrentState() {
        let font = contentDescriptionLabel.font ?? .systemFont(ofSize: 12)
        let width = contentDescriptionLabel.bounds.width > 0
            ? contentDescriptionLabel.bounds.width
            : UIScreen.main.bounds.width - 16

        guard let result = CollapsedTextFormatter.make(
            fullText: fullText,
            isExpanded: isExpanded,
            labelFont: font,
            labelTextColor: .appPrimaryText,
            actionTextColor: .systemBlue,
            maxCollapsedLines: 3,
            labelWidth: width
        ) else {
            contentDescriptionLabel.isHidden = true
            moreRange = nil
            return
        }

        contentDescriptionLabel.isHidden = false
        contentDescriptionLabel.numberOfLines = result.numberOfLines
        contentDescriptionLabel.attributedText = result.attributedText
        moreRange = result.moreRange
    }

    /// Анимация большого сердца по центру поста.
    private func animateBigHeart() {
        bigHeartImageView.layer.removeAllAnimations()
        bigHeartImageView.alpha = 0
        bigHeartImageView.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)

        UIView.animate(
            withDuration: 0.15,
            delay: 0,
            options: [.curveEaseOut]
        ) {
            self.bigHeartImageView.alpha = 1
            self.bigHeartImageView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        } completion: { _ in
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                usingSpringWithDamping: 0.5,
                initialSpringVelocity: 0.8,
                options: []
            ) {
                self.bigHeartImageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            } completion: { _ in
                UIView.animate(
                    withDuration: 0.2,
                    delay: 0.3,
                    options: [.curveEaseIn]
                ) {
                    self.bigHeartImageView.alpha = 0
                    self.bigHeartImageView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                }
            }
        }
    }

    @objc private func handleLabelTap(_ gesture: UITapGestureRecognizer) {
        guard
            let text = contentDescriptionLabel.attributedText,
            let label = gesture.view as? UILabel,
            let moreRange = moreRange
        else { return }

        let location = gesture.location(in: label)

        let textStorage = NSTextStorage(attributedString: text)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: label.bounds.size)
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = label.numberOfLines
        textContainer.lineBreakMode = label.lineBreakMode

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        let index = layoutManager.characterIndex(
            for: location,
            in: textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil
        )

        if NSLocationInRange(index, moreRange) {
            delegate?.postCellDidTapMore(self)
        }
    }

    @objc private func handleLikeTap() {
        delegate?.postCellDidTapLike(self)
    }

    @objc private func handleDoubleTap() {
        if !isLikedState {
            delegate?.postCellDidTapLike(self)
            animateBigHeart()
        } else {
            delegate?.postCellDidTapLike(self)
        }
    }
    
    @objc private func handleShareTap() {
        delegate?.postCellDidTapShare(self)
    }
    
    @objc private func handleImageTap() {
        guard !mediaImageView.isHidden, mediaImageView.image != nil else { return }
        delegate?.postCellDidTapImage(self)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension PostCollectionViewCell: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        // Не перехватывать тапы по кнопкам/контролам
        if touch.view is UIControl {
            return false
        }

        // Область лайка свой тап
        if touch.view === likesImage || touch.view === likesLabel {
            return false
        }

        return true
    }
}
