import UIKit

/// Ячейка-заглушка "здесь пока ничего нет…".
final class EmptyMessageCell: UICollectionViewCell {

    static let reuseId = "EmptyMessageCell"

    /// Текстовое сообщение по центру ячейки.
    private lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.textColor = .appSecondaryText
        label.font = .systemFont(ofSize: 15)
        label.numberOfLines = 0
        
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = .clear
        contentView.addSubview(label)
    
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -324)
        ])
    }

    /// Подставляет текст в зависимости от активной вкладки.
    func configure(for tab: ProfileTab) {
        switch tab {
        case .main, .posts, .photos, .music:
            label.text = "Здесь пока ничего нет..."
        }
    }
}
