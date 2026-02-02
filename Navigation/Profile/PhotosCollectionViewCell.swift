import UIKit

final class PhotosCollectionViewCell: UICollectionViewCell {
   
    static let reuseId = "PhotosCollectionViewCell"
    
    private lazy var imageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.translatesAutoresizingMaskIntoConstraints = false
        
        return image
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        contentView.clipsToBounds = true
        contentView.addSubview(imageView)
        
        NSLayoutConstraint.activate(
            [
                imageView.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor
                ),
                imageView.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor
                ),
                imageView.topAnchor.constraint(
                    equalTo: contentView.topAnchor
                ),
                imageView.bottomAnchor.constraint(
                    equalTo: contentView.bottomAnchor
                )
            ]
        )
    }
    
    func setupCell(photo: Photo) {
        imageView.image = UIImage(named: photo.imageName)
    }
}
