import UIKit

/// Ячейка сторис.
final class StoryCollectionViewCell: UICollectionViewCell {
    
    static let reuseId = "StoryCollectionViewCell"
    
    /// Таска загрузки изображения
    private var imageTask: Task<Void, Never>?
    
    /// Круглая картинка  сторис
    private lazy var circleView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .appSecondaryBackground
        imageView.layer.cornerRadius = 40
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderWidth = 2.5
        imageView.layer.borderColor = UIColor.appAccent.cgColor
        
        return imageView
    }()
    
    /// Имя автора
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10)
        label.textAlignment = .center
        label.textColor = .appPrimaryText
        label.numberOfLines = 2
        
        return label
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
        imageTask?.cancel()
        imageTask = nil
        circleView.image = nil
    }
    
    private func configureUI() {
        [circleView, titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            circleView.topAnchor.constraint(equalTo: contentView.topAnchor),
            circleView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            circleView.widthAnchor.constraint(equalToConstant: 80),
            circleView.heightAnchor.constraint(equalToConstant: 80),
            
            titleLabel.topAnchor.constraint(equalTo: circleView.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    /// Конфигурация ячейки моделью сториc
    func configure(with story: FeedStory) {
        titleLabel.text = story.authorName
        
        // Рамка: синяя для новых, белая для уже просмотренных
        circleView.layer.borderColor = (story.isViewed ? UIColor.white : UIColor.appAccent).cgColor
        
        // Загрузка первого фото истории как аватар
        imageTask?.cancel()
        imageTask = circleView.setImage(
            from: story.avatarURLForDisplay,
            placeholder: nil
        )
    }
}
