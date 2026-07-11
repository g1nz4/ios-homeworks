import UIKit

/// Заголовок секции профиля (reusable view для header’а секции).
final class ProfileSectionTitleView: UICollectionReusableView {

    static let reuseId = "ProfileSectionTitleView"

    /// Текст заголовка секции.
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .appPrimaryText
        
        return label
    }()

    /// Тонкая разделительная линия сверху.
    private lazy var topSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .appSeparator
        
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
       configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        backgroundColor = .appBackground
        
        [titleLabel, topSeparatorView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
   
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),

            topSeparatorView.topAnchor.constraint(equalTo: topAnchor),
            topSeparatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topSeparatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            topSeparatorView.heightAnchor.constraint(equalToConstant: 0.7)
        ])
    }

    func configure(title: String) {
        titleLabel.text = title
    }
}
