import UIKit

/// Хедер с надписью "Главная"
final class TitleHeaderView: UICollectionReusableView {
    static let reuseId = "TitleHeaderView"
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .headline).withSize(26)
        label.textColor = .appPrimaryText
        
        return label
    }()
   
    override init(frame: CGRect) {
        super.init(frame: frame)

       configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureUI() {
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func configurePrimary(title: String) {
        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .headline).withSize(26)
    }

    func configureSecondary(title: String) {
        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .footnote).withSize(18)
    }
}
