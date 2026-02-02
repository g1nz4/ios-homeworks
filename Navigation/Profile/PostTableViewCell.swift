import UIKit
import StorageService

final class PostTableViewCell: UITableViewCell {

    static let reuseId = "PostCell"
   
    private lazy var postCellView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        
        return view
    }()
    
    private lazy var postCellImage: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFit
        image.backgroundColor = .black
        
        return image
    }()
    
    private lazy var postCellAuthor: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 20.0, weight: .bold)
        label.textColor = .black
        label.numberOfLines = 2
        
        return label
    }()
    
    private lazy var postCellDescription: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14.0, weight: .regular)
        label.textColor = .systemGray
        label.numberOfLines = 0
        
        return label
    }()
    
    private lazy var postCellLikes: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16.0, weight: .regular)
        label.textColor = .black

        return label
    }()
    
    private lazy var postCellVievvs: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16.0, weight: .regular)
        label.textColor = .black
        
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
       
        addSubViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCell(post: MyPost) {
        postCellImage.image = UIImage(named: post.image)
        postCellAuthor.text = post.author
        postCellDescription.text = post.description
        postCellLikes.text = "Likes: \(post.likes)"
        postCellVievvs.text = "Views: \(post.views)"
        
    }
    
    private func addSubViews() {
        contentView.addSubview(postCellView)
        postCellView.addSubview(postCellImage)
        postCellView.addSubview(postCellAuthor)
        postCellView.addSubview(postCellDescription)
        postCellView.addSubview(postCellLikes)
        postCellView.addSubview(postCellVievvs)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate(
            [
                postCellView.topAnchor.constraint(
                    equalTo: contentView.topAnchor
                ),
                postCellView.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor
                ),
                postCellView.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor
                ),
                postCellView.bottomAnchor.constraint(
                    equalTo: contentView.bottomAnchor
                ),
                
                postCellAuthor.leadingAnchor.constraint(
                    equalTo: postCellView.leadingAnchor,
                    constant: 16.0
                ),
                postCellAuthor.trailingAnchor.constraint(
                    equalTo: postCellView.trailingAnchor,
                    constant: -16.0
                ),
                postCellAuthor.topAnchor.constraint(
                    equalTo: postCellView.topAnchor,
                    constant: 16.0
                ),
                
                postCellImage.leadingAnchor.constraint(
                    equalTo: postCellView.leadingAnchor
                ),
                postCellImage.trailingAnchor.constraint(
                    equalTo: postCellView.trailingAnchor
                ),
                postCellImage.topAnchor.constraint(
                    equalTo: postCellAuthor.bottomAnchor,
                    constant: 12.0
                ),
                postCellImage.widthAnchor.constraint(
                    equalTo: postCellView.widthAnchor
                ),
                postCellImage.heightAnchor.constraint(
                    equalTo: postCellImage.widthAnchor,
                ),
                
                postCellDescription.leadingAnchor.constraint(
                    equalTo: postCellView.leadingAnchor,
                    constant: 16.0
                ),
                postCellDescription.trailingAnchor.constraint(
                    equalTo: postCellView.trailingAnchor,
                    constant: -16.0
                ),
                postCellDescription.topAnchor.constraint(
                    equalTo: postCellImage.bottomAnchor,
                    constant: 16.0
                ),
                postCellDescription.bottomAnchor.constraint(
                    equalTo: postCellView.bottomAnchor,
                    constant: -60.0
                ),
                
                postCellLikes.leadingAnchor.constraint(
                    equalTo: postCellView.leadingAnchor,
                    constant: 16.0
                ),
                postCellLikes.topAnchor.constraint(
                    equalTo: postCellDescription.bottomAnchor,
                    constant: 16.0
                ),
                postCellLikes.bottomAnchor.constraint(
                    equalTo: postCellView.bottomAnchor,
                    constant: -16.0
                ),
                
                postCellVievvs.trailingAnchor.constraint(
                    equalTo: postCellView.trailingAnchor,
                    constant: -16.0
                ),
                postCellVievvs.topAnchor.constraint(
                    equalTo: postCellDescription.bottomAnchor,
                    constant: 16.0
                ),
                postCellVievvs.bottomAnchor.constraint(
                    equalTo: postCellView.bottomAnchor,
                    constant: -16.0
                )
            ]
        )
    }
}


