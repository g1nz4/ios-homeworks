import UIKit
import iOSIntPackage

final class PhotosViewController: UIViewController {
    
    fileprivate lazy var photos: [Photo] = Photo.allPhotos()
   
    private var isSubscribed = false
    private var publishedImages: [UIImage] = []
    private let imagePublisherFacade = ImagePublisherFacade()
    
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
            forCellWithReuseIdentifier: PhotosCollectionViewCell.reuseId
        )
        return collection
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title =  "Photo Gallery"
        view.addSubview(photoGalerry)
        setupConstraints()
        subscribeToImagePublisherIfNeeded()
        startImagesPublishing()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        photoGalerry.collectionViewLayout.invalidateLayout()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    deinit {
        imagePublisherFacade.removeSubscription(for: PhotosViewController.self as! ImageLibrarySubscriber)
        isSubscribed = false
    }
    
    private func setupConstraints() {
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
    
    private func subscribeToImagePublisherIfNeeded() {
        guard !isSubscribed else { return }
        imagePublisherFacade.subscribe(self)
        isSubscribed = true
    }
    
    private func startImagesPublishing() {
        imagePublisherFacade.addImagesWithTimer(
            time: 0.5,
            repeat: 20,
            userImages: photos.compactMap { UIImage(named: $0.imageName) }
        )
    }
    
    private func updatePhotosFromPublishedImages() {
        DispatchQueue.main.async { [weak self] in
            self?.photoGalerry.reloadData()
        }
    }
}

extension PhotosViewController: UICollectionViewDataSource {
   
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        publishedImages.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PhotosCollectionViewCell.reuseId,
            for: indexPath
        ) as! PhotosCollectionViewCell
        
        let photo = photos[indexPath.row]
        cell.setupCell(photo: photo)
                        
        return cell
    }
}

extension PhotosViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let iteritemSpacing = (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.minimumInteritemSpacing ?? 0.0
        let width = collectionView.bounds.width - (Constant.itemsInRow - 1) * iteritemSpacing - 16.0
        let itemWidth = floor(width / Constant.itemsInRow)
        
        return CGSize(width: itemWidth, height: itemWidth)
    }
        
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        
        UIEdgeInsets(
            top: 8.0,
            left: 8.0,
            bottom: 8.0,
            right: 8.0
        )
    }
}

extension PhotosViewController: ImageLibrarySubscriber {
    func receive(images: [UIImage]) {
        publishedImages = images
        updatePhotosFromPublishedImages()
    }
}
