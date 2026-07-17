import UIKit

/// Ячейка друга в списке друзей.
final class FriendCell: UICollectionViewCell {
   
    static let reuseId = "FriendCell"
    /// Текущая таска загрузки аватара.
    private var imageTask: Task<Void, Never>?
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 0.3
        imageView.layer.borderColor = UIColor.appPrimaryText.cgColor
        imageView.layer.cornerRadius = 30
        
        return imageView
    }()
    
    /// Индикатор онлайна — маленький кружок внизу/справа от аватара.
    private lazy var onlineIndicator: UIView = {
        let view = UIView()
        view.isHidden = false
        view.layer.borderWidth = 0.2
        view.layer.borderColor = UIColor.appPrimaryText.cgColor
        view.layer.cornerRadius = 5.0
      
        return view
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .label
        
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
     
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
       
        return stackView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Сброс состояние перед переиспользованием.
    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        imageView.image = nil
        nameLabel.text = nil
        subtitleLabel.text = nil
        subtitleLabel.isHidden = false
    }
    
    private func configureUI() {
        contentView.backgroundColor = .appBackground
        [imageView, onlineIndicator, stackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 60),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            
            onlineIndicator.centerXAnchor.constraint(equalTo: imageView.centerXAnchor, constant: 22),
            onlineIndicator.centerYAnchor.constraint(equalTo: imageView.centerYAnchor, constant: 21),
            onlineIndicator.widthAnchor.constraint(equalToConstant: 10),
            onlineIndicator.heightAnchor.constraint(equalToConstant: 10),
            
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            stackView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
        ])
    }
    
    func configure(name: String, avatarPath: String?, subtitleText: String?, isOnline: Bool) {
        nameLabel.text = name

        if let text = subtitleText, !text.isEmpty {
            subtitleLabel.isHidden = false
            subtitleLabel.text = text
        } else {
            subtitleLabel.isHidden = true
            subtitleLabel.text = nil
        }

        onlineIndicator.backgroundColor = isOnline ? .systemGreen : .systemRed

        imageTask?.cancel()
        imageTask = imageView.setImage(
            from: avatarPath,
            placeholder: UIImage(named: "avatar_placeholder")
        )
    }
}
