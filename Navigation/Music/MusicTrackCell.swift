import UIKit

/// Ячейка музыкального трека.
final class MusicTrackCell: UICollectionViewCell {

    static let reuseId = "MusicTrackCell"

    /// Нажатие по кнопке Play/Pause
    var onPlayPauseTapped: (() -> Void)?

    /// Нажатие по правой кнопке (плюс/галочка/крестик)
    var onSecondaryTapped: (() -> Void)?

    /// Таска для загрузки обложки
    private var coverLoadTask: Task<Void, Never>?
    
    private var currentCoverFileName: String?

    private lazy var coverImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 4
        view.backgroundColor = .secondarySystemBackground
        
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .appPrimaryText
        label.numberOfLines = 1
        
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .appPrimaryText
        label.numberOfLines = 1
        
        return label
    }()

    private lazy var textStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 2
        
        return stack
    }()

    /// Кнопка Play/Pause справа
    private lazy var playPauseButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        button.setImage(UIImage(systemName: "play.fill", withConfiguration: config), for: .normal)
        button.tintColor = .appAccent
        button.addTarget(self, action: #selector(playPauseButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var secondaryButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        button.tintColor = .appAccent
        button.addTarget(self, action: #selector(secondaryButtonTapped), for: .touchUpInside)
        
        return button
    }()

    private lazy var rightButtonsStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [playPauseButton, secondaryButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        
        return stack
    }()

   
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        coverLoadTask?.cancel()
        coverLoadTask = nil

        coverImageView.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
        currentCoverFileName = nil

        onPlayPauseTapped = nil
        onSecondaryTapped = nil
    }


    private func configureUI() {
        contentView.backgroundColor = .appBackground
        contentView.clipsToBounds = true

        [coverImageView, textStack, rightButtonsStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        let selectedBG = UIView()
        selectedBG.backgroundColor = UIColor.appSecondaryBackground.withAlphaComponent(0.6)
        selectedBackgroundView = selectedBG
    
        NSLayoutConstraint.activate([
            coverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            coverImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            coverImageView.widthAnchor.constraint(equalToConstant: 44),
            coverImageView.heightAnchor.constraint(equalToConstant: 44),

            rightButtonsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            rightButtonsStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            playPauseButton.widthAnchor.constraint(equalToConstant: 24),
            playPauseButton.heightAnchor.constraint(equalToConstant: 24),

            secondaryButton.widthAnchor.constraint(equalToConstant: 24),
            secondaryButton.heightAnchor.constraint(equalToConstant: 24),

            textStack.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: rightButtonsStack.leadingAnchor, constant: -12),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 8),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    func configure(
        with item: MusicTrackItemViewData,
        isPlaying: Bool,
        isInMyTracks: Bool,
        isMyTracksTab: Bool
    ) {

        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle

        let placeholder = UIImage(named: "placeholder_album")

        if item.coverFileName != currentCoverFileName {
            currentCoverFileName = item.coverFileName
            
            coverLoadTask?.cancel()
            coverLoadTask = nil
            
            coverImageView.image = placeholder
            
            coverLoadTask = coverImageView.setImage(
                from: item.coverFileName,
                placeholder: placeholder
            )
        }

        if let coverPath = item.coverFileName, !coverPath.isEmpty {
            coverImageView.contentMode = .scaleAspectFill
            coverImageView.backgroundColor = .secondarySystemBackground
            coverImageView.tintColor = nil
        } else {
            coverImageView.contentMode = .scaleAspectFit
            coverImageView.backgroundColor = .clear
            coverImageView.tintColor = .systemBlue
        }

        // Цвет названия меняем, если трек активный
        titleLabel.textColor = isPlaying ? .appAccent : .appSecondaryText

        // Кнопка play/pause
        let playConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        let playImageName = isPlaying ? "pause.fill" : "play.fill"
        playPauseButton.setImage(
            UIImage(systemName: playImageName, withConfiguration: playConfig),
            for: .normal
        )

        // Правая кнопка:
        // - на главной: plus / checkmark
        // - на мои треки: xmark
        let secondaryConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        let secondaryImageName: String

        if isMyTracksTab {
            secondaryImageName = "xmark"
        } else {
            secondaryImageName = isInMyTracks ? "checkmark" : "plus"
        }

        secondaryButton.setImage(
            UIImage(systemName: secondaryImageName, withConfiguration: secondaryConfig),
            for: .normal
        )

        secondaryButton.tintColor = isMyTracksTab ? .systemRed : .systemBlue
    }

    @objc private func playPauseButtonTapped() {
        onPlayPauseTapped?()
    }

    @objc private func secondaryButtonTapped() {
        onSecondaryTapped?()
    }
}
