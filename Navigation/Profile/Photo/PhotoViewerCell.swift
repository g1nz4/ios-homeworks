import UIKit

/// Ячейка для полноэкранного просмотра фото с зумом.
final class PhotoViewerCell: UICollectionViewCell, UIScrollViewDelegate {

    static let reuseId = "PhotoViewerCell"

    /// Текущая задача загрузки изображения.
    private var currentTask: Task<Void, Never>?

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.5
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.backgroundColor = .black
        scrollView.delegate = self
        
        return scrollView
    }()

    /// Публичный, чтобы viewer мог, при необходимости, обращаться к картинке.
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        currentTask?.cancel()
        currentTask = nil
        imageView.image = nil
        scrollView.setZoomScale(1.0, animated: false)
    }

    private func setupUI() {
        contentView.addSubview(scrollView)
        scrollView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }

    private func setupGestures() {
        let doubleTap = UITapGestureRecognizer(
            target: self,
            action: #selector(handleDoubleTap(_:))
        )
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }

    func configure(with url: URL) {
        currentTask?.cancel()
        imageView.image = nil
        scrollView.setZoomScale(1.0, animated: false)

        currentTask = Task { [weak self] in
            guard let self else { return }

            let image = await ImageLoader.shared.loadImage(from: url)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                self.imageView.image = image
            }
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // Центрируем картинку при зуме, чтобы она не прилипала к краям, когда становится меньше, чем размер scrollView.
        let boundsSize = scrollView.bounds.size
        var frameToCenter = imageView.frame

        frameToCenter.origin.x = frameToCenter.size.width < boundsSize.width
            ? (boundsSize.width - frameToCenter.size.width) / 2
            : 0
        frameToCenter.origin.y = frameToCenter.size.height < boundsSize.height
            ? (boundsSize.height - frameToCenter.size.height) / 2
            : 0

        imageView.frame = frameToCenter
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        let zoomed = scrollView.zoomScale > 1.0
        scrollView.setZoomScale(zoomed ? 1.0 : 2.0, animated: true)
    }
}
