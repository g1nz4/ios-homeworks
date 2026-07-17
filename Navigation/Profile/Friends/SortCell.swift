import UIKit

/// Ячейка с контролом сортировки друзей.
final class SortCell: UICollectionViewCell {
    
    static let reuseId = "SortCell"

    /// Колбэк на тап по ячейке (показать Action Sheet выбора сортировки)
    var onTap: (() -> Void)?

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .appSecondaryText
        
        return label
    }()

    private lazy var arrowsImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "arrow.up.arrow.down")
        imageView.tintColor = .appSecondaryText
        
        return imageView
    }()

    private lazy var stack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, arrowsImageView])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 8
        
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
        contentView.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16.0),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        contentView.addGestureRecognizer(tap)
    }

    func configure(sortTitle: String) {
        titleLabel.text = "Сортировать: \(sortTitle)"
    }
    
    @objc private func handleTap() {
        onTap?()
    }
}
