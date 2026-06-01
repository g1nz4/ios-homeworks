import UIKit

final class PhotosTableViewCell: UITableViewCell {
   
    static let reuseId = "PhotosTableViewCell"
    
    fileprivate lazy var photo: [Photo] = Photo.returnFirstFew(count: 8)
    
    private enum Constant {
        static let spacing: CGFloat = 8.0
        static let items: CGFloat = 4.0
    }
    
    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24.0, weight: .bold)
        label.text = "Photos"
        label.textColor = .appPrimaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()

    private lazy var symbol: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(systemName: "arrowshape.right")
        image.tintColor = .appSecondaryText
        image.translatesAutoresizingMaskIntoConstraints = false
        
        return image
    }()
    
    private lazy var photoGalerry: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = Constant.spacing
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(
            PhotoViewCell.self,
            forCellWithReuseIdentifier: PhotoViewCell.reuseId
        )
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        
        return collectionView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .appSecondaryBackground
        addSubViews()
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
  
    private func addSubViews() {
        [label, symbol, photoGalerry].forEach() {
            contentView.addSubview($0)
        }
    }
    
    private func setupView() {
        
        NSLayoutConstraint.activate(
            [
                label.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor,
                    constant: 12.0
                ),
                label.topAnchor.constraint(
                    equalTo: contentView.topAnchor,
                    constant: 12.0
                ),

                symbol.centerYAnchor.constraint(
                    equalTo: label.centerYAnchor
                ),
                symbol.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor,
                    constant: -12.0
                ),
                symbol.widthAnchor.constraint(
                    equalToConstant: 24.0
                ),
                symbol.heightAnchor.constraint(
                    equalToConstant: 24.0
                ),
                
                photoGalerry.topAnchor.constraint(
                    equalTo: label.bottomAnchor,
                    constant: 12.0
                ),
                photoGalerry.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor,
                    constant: 12.0
                ),
                photoGalerry.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor,
                    constant: -12.0
                ),
                photoGalerry.bottomAnchor.constraint(
                    equalTo: contentView.bottomAnchor,
                    constant: -12.0
                ),
                photoGalerry.heightAnchor.constraint(
                    equalToConstant: 90.0
                )
            ]
        )
    }
}

extension PhotosTableViewCell: UICollectionViewDataSource {
    
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        photo.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PhotoViewCell.reuseId,
            for: indexPath
        ) as! PhotoViewCell
        let photo = photo[indexPath.row]
        cell.setupCell(photo: photo)
                        
        return cell
    }
}

extension PhotosTableViewCell: UICollectionViewDelegateFlowLayout {
   
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = photoGalerry.bounds.width - (Constant.items - 1) * Constant.spacing
        let itemWidth = floor(width / Constant.items)
        
        return CGSize(width: itemWidth, height: itemWidth)
    }
}



