import UIKit

/// Хедер секции "Меню" с кнопкой информации справа
final class MenuHeaderView: UICollectionReusableView {

    static let reuseId = "MenuHeaderView"

    /// Колбэк на тап по кнопке info
    var onInfoTap: (() -> Void)?

    /// Заголовок секции
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline).withSize(26)
        label.textColor = .appPrimaryText
        label.text = "Меню"
        
        return label
    }()

    /// Кнопка с иконкой "i"
    private lazy var infoButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        let image = UIImage(systemName: "info.circle", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .appPrimaryText
        button.backgroundColor = .clear
        button.layer.cornerRadius = 15
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(infoTapped), for: .touchUpInside)
        
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        [titleLabel, infoButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
   
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),

            infoButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 8),
            infoButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            infoButton.widthAnchor.constraint(equalToConstant: 30),
            infoButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    func configure(title: String) {
        titleLabel.text = title
    }

    @objc private func infoTapped() {
        onInfoTap?()
    }
}
