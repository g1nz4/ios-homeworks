import UIKit

class PhotoViewCell: UICollectionViewCell {
    
    static let reuseId = "PhotoCollectionViewCell"
    
    private lazy var image: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        image.layer.cornerRadius = 6.0
    
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
       
        contentView.addSubview(image)
        
        NSLayoutConstraint.activate(
            [
                image.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor
                ),
                image.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor
                ),
                image.topAnchor.constraint(
                    equalTo: contentView.topAnchor
                ),
                image.bottomAnchor.constraint(
                    equalTo: contentView.bottomAnchor
                )
            ]
        )
    }
    
    func setupCell(photo: Photo) {
        image.image = UIImage(named: photo.imageName)
    }
}


