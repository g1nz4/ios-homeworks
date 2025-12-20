import UIKit

class PhotosViewController: UIViewController {
    
    fileprivate lazy var photos: [Photo] = Photo.allPhotos()
    
    private enum Constant {
        static let spacing: CGFloat = 8.0
        static let itemsInRow: CGFloat = 3.0
    }
    
    private lazy var photoGalerry: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = Constant.spacing
        layout.minimumInteritemSpacing = Constant.spacing
        let collection = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.dataSource = self
        collection.delegate = self
        collection.register(
            PhotosCollectionViewCell.self,
            forCellWithReuseIdentifier: PhotosCollectionViewCell.reusedId
        )
        return collection
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title =  "Photo Gallery"
        view.addSubview(photoGalerry)
        setupConctraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.isHidden = false
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        photoGalerry.collectionViewLayout.invalidateLayout()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.navigationBar.isHidden = true
    }
        
    private func setupConctraints() {
        NSLayoutConstraint.activate(
            [
                photoGalerry.topAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.topAnchor
                ),
                photoGalerry.bottomAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.bottomAnchor
                ),
                photoGalerry.leadingAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.leadingAnchor
                ),
                photoGalerry.trailingAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.trailingAnchor
                )
            ]
        )
    }
}

extension PhotosViewController: UICollectionViewDataSource {
   
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotosCollectionViewCell.reusedId, for: indexPath) as! PhotosCollectionViewCell
        let photo = photos[indexPath.row]
        cell.setupCell(photo: photo)
                        
        return cell
    }
}

extension PhotosViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.reloadData()
        let iteritemSpacing = (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.minimumInteritemSpacing ?? 0.0
        let width = collectionView.bounds.width - (Constant.itemsInRow - 1) * iteritemSpacing - 16.0
        let itemWidth = floor(width / Constant.itemsInRow)
        
        return CGSize(width: itemWidth, height: itemWidth)
    }
        
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(
            top: 8.0,
            left: 8.0,
            bottom: 8.0,
            right: 8.0
        )
    }
}
