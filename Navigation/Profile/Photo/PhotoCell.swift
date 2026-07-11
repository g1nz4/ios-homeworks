import UIKit

/// Ячейка для отображения отдельной фотографии.
final class PhotoCell: UICollectionViewCell {

    static let reuseId = "PhotoCell"

    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 6.0
        
        return view
    }()

    /// Текущая задача загрузки изображения.
    private var loadTask: Task<Void, Never>?

    override init(frame: CGRect) {
        super.init(frame: frame)
      
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        loadTask?.cancel()
        loadTask = nil
        imageView.image = nil
    }

    private func setupUI() {
        contentView.backgroundColor = .appBackground
        contentView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    /// Конфигурация ячейки URL‑ом картинки.
    func configure(with url: URL) {
        // На всякий случай отмена предыдущей задачи
        loadTask?.cancel()
        imageView.image = nil

        loadTask = Task { [weak self] in
            guard let self else { return }

            if let image = await ImageLoader.shared.loadImage(from: url) {
                guard !Task.isCancelled else { return }
               
                await MainActor.run {
                    self.imageView.image = image
                }
            }
        }
    }
}
