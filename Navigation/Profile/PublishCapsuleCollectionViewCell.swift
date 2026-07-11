import UIKit

/// Капсула "Опубликовать пост" в коллекции.
final class PublishCapsuleCollectionViewCell: UICollectionViewCell {

    static let reuseId = "PublishCollectionViewCell"

    private lazy var container: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .appBackground
        view.layer.cornerRadius = 18
        view.clipsToBounds = true
        
        return view
    }()

    private lazy var iconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "plus.circle"))
        imageView.tintColor = .appAccent
        
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Опубликовать пост"
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .appAccent
        label.textAlignment = .center
        
        return label
    }()

    /// Горизонтальный стек с иконкой и заголовком.
    private lazy var stack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        stack.distribution = .fill
        
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

        contentView.addSubview(container)
        container.addSubview(stack)
  
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            container.heightAnchor.constraint(equalToConstant: 44),

            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
    }
}
