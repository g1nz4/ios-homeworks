import UIKit

/// Ячейка для отображения фото‑альбома (cover + название).
final class AlbumCell: UICollectionViewCell {

    static let reuseId = "AlbumCell"

    /// Обложка альбома.
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.image = UIImage(named: "albumPlaceholder")
        
        return view
    }()

    /// Название альбома на полупрозрачном чёрном фоне.
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .white
        label.numberOfLines = 2
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        
        return label
    }()

    /// Текущая таска загрузки обложки, чтобы её можно было отменить при переиспользовании.
    private var loadTask: Task<Void, Never>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Настройка интерфейса.
    private func setupUI() {
        contentView.backgroundColor = .appBackground
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
       
        [imageView, titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 24)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        // Отменить старую загрузку, сбрасить картинку на плейсхолдере
        loadTask?.cancel()
        loadTask = nil
        imageView.image = UIImage(named: "albumPlaceholder")
        titleLabel.text = nil
    }

    /// Конфигурация ячейки данными альбома.
    func configure(with album: PhotoAlbum, coverURL: URL?) {
        titleLabel.text = album.title

        guard let coverURL else { return }

        // Отменить предыдущую загрузку, если она ещё идёт
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }

            if let image = await ImageLoader.shared.loadImage(from: coverURL) {
                await MainActor.run {
                    self.imageView.image = image
                }
            }
        }
    }
}
