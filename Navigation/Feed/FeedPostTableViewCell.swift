//import UIKit
//
//final class FeedPostTableViewCell: UITableViewCell {
//    
//    static let reuseId = "FeedPostCell"
//    
//    private lazy var containerView: UIView = {
//        let view = UIView()
//        view.translatesAutoresizingMaskIntoConstraints = false
//        view.backgroundColor = .clear
//        
//        return view
//    }()
//    
//    private lazy var postImageView: UIImageView = {
//        let image = UIImageView()
//        image.clipsToBounds = true
//        image.contentMode = .scaleAspectFill
//        image.backgroundColor = .black
//        
//        return image
//    }()
//    
//    private lazy var titleLabel: UILabel = {
//        let label = UILabel()
//        label.font = .systemFont(ofSize: 20, weight: .bold)
//        label.textColor = .black
//        label.numberOfLines = 2
//        
//        return label
//    }()
//    
//    private lazy var authorLabel: UILabel = {
//        let label = UILabel()
//        label.font = .systemFont(ofSize: 14, weight: .semibold)
//        label.textColor = .systemGray
//        label.numberOfLines = 1
//        
//        return label
//    }()
//    
//    private lazy var descriptionLabel: UILabel = {
//        let label = UILabel()
//        label.font = .systemFont(ofSize: 14, weight: .regular)
//        label.textColor = .darkGray
//        label.numberOfLines = 0
//        
//        return label
//    }()
//    
//    private lazy var likesLabel: UILabel = {
//        let label = UILabel()
//        label.font = .systemFont(ofSize: 14, weight: .regular)
//        label.textColor = .black
//        
//        return label
//    }()
//    
//    private lazy var viewsLabel: UILabel = {
//        let label = UILabel()
//        label.font = .systemFont(ofSize: 14, weight: .regular)
//        label.textColor = .black
//        
//        return label
//    }()
//    
//    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        setupViews()
//        setupConstraints()
//    }
//        
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    func configure(with post: FeedPost) {
//        postImageView.image = UIImage(named: post.image)
//        titleLabel.text = post.title
//        authorLabel.text = post.author
//        descriptionLabel.text = post.description
//        likesLabel.text = "Likes: \(post.likes)"
//        viewsLabel.text = "Views: \(post.views)"
//    }
//    
//    private func setupViews() {
//        contentView.addSubview(containerView)
//        [titleLabel, authorLabel, postImageView, descriptionLabel, likesLabel, viewsLabel].forEach() {
//            $0.translatesAutoresizingMaskIntoConstraints = false
//            containerView.addSubview($0)
//        }
//    }
//    
//    private func setupConstraints() {
//        NSLayoutConstraint.activate([
//            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
//            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
//            
//            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
//            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
//            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
//            
//            authorLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
//            authorLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
//            authorLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
//            
//            postImageView.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 8),
//            postImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
//            postImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
//            postImageView.widthAnchor.constraint(equalTo: containerView.widthAnchor),
//            postImageView.heightAnchor.constraint(equalTo: postImageView.widthAnchor),
//            
//            descriptionLabel.topAnchor.constraint(equalTo: postImageView.bottomAnchor, constant: 12),
//            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
//            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
//            
//            likesLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 12),
//            likesLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
//            likesLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
//            
//            viewsLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 12),
//            viewsLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
//            viewsLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
//        ])
//    }
//}
