import UIKit

/// Квадратная ячейка пункта меню (иконка + подпись + цветная тень)
final class MenuItemCell: UICollectionViewCell {

    static let reuseId = "MenuItemCell"

    /// Контейнер вокруг иконки — скруглённый, с бордером и тенью
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .appBackground
        view.layer.cornerRadius = 18
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.appSecondaryText.withAlphaComponent(0.2).cgColor
        view.clipsToBounds = false
        
        return view
    }()

    /// Иконка пункта меню
    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFit
        
        return view
    }()

    /// Подпись под иконкой, до 2 строк
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .appSecondaryText
        label.numberOfLines = 2
        label.textAlignment = .center
        
        return label
        
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Верстка контейнера + иконки + подписи
    private func configureUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        [containerView, titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        containerView.addSubview(iconView)
   
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 64),
            containerView.heightAnchor.constraint(equalTo: containerView.widthAnchor),

            iconView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalTo: iconView.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 6),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ])
    }

    /// Обновляет форму тени после лейаута
    override func layoutSubviews() {
        super.layoutSubviews()

        let rect = containerView.convert(containerView.bounds, to: self)
        layer.shadowPath = UIBezierPath(
            roundedRect: rect,
            cornerRadius: containerView.layer.cornerRadius
        ).cgPath
    }

    /// Публичная конфигурация ячейки пункта меню
    func configure(with item: MenuItem) {
        titleLabel.text = item.title
        iconView.image = UIImage(systemName: item.systemImageName)
        iconView.backgroundColor = .clear

        let itemColor = item.color
        iconView.tintColor = itemColor

        containerView.layer.shadowColor = itemColor.cgColor
        containerView.layer.shadowOpacity = 0.6
        containerView.layer.shadowRadius = 6
        containerView.layer.shadowOffset = .zero
        containerView.layer.masksToBounds = false
    }
}
