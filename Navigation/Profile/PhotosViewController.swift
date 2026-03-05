import UIKit
import iOSIntPackage

final class PhotosViewController: UIViewController {
    
    fileprivate lazy var photos: [Photo] = Photo.allPhotos()
    
    private lazy var originalImages: [UIImage] = photos.compactMap {
        UIImage(named: $0.imageName)
    }
    private var processedImages: [UIImage] = []
    private let imageProcessor = ImageProcessor()
    
    private enum Constant {
        static let spacing: CGFloat = 8.0
        static let itemsInRow: CGFloat = 3.0
    }
    
    private lazy var photoGallery: UICollectionView = {
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
        view.addSubview(photoGallery)
        setupConstraints()
        setupBarButton()
        processedImages = originalImages
        photoGallery.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        photoGallery.collectionViewLayout.invalidateLayout()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    private func setupBarButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Run",
            style: .plain,
            target: self,
            action: #selector(runExperiments)
        )
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate(
            [
                photoGallery.topAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.topAnchor
                ),
                photoGallery.bottomAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.bottomAnchor
                ),
                photoGallery.leadingAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.leadingAnchor
                ),
                photoGallery.trailingAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.trailingAnchor
                )
            ]
        )
    }
    
    
    private func processImagesWithQoS(
        _ qos: QualityOfService,
        filter: ColorFilter,
        inputImages: [UIImage]
    ) {
        guard !inputImages.isEmpty else { return }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        imageProcessor.processImagesOnThread(
            sourceImages: inputImages,
            filter: filter,
            qos: qos
        ) { [weak self] cgImages in
            guard let self = self else { return }
            
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            print("Фильтр \(filter) с qos \(qos) занял \(elapsed) секунд, кол-во изображений: \(inputImages.count)")
            
            let uiImages = cgImages.compactMap { cgImage in
                cgImage.map { UIImage(cgImage: $0) }
            }
            
            DispatchQueue.main.async {
                self.processedImages = uiImages
                self.photoGallery.reloadData()
            }
        }
    }
    
    @objc private func runExperiments() {
        processImagesWithQoS(
            .background,
            filter: .chrome,
            inputImages: originalImages
        )
    }
/*
 Результаты замеров времени (симулятор iPhone 17 Pro, 20 изображений)
 
 Фильтр noir:
 - qos .utility занял 1.4518240690231323 секунд
 - qos .background занял 7.448648929595947 секунд
 - qos .default занял 1.4336200952529907 секунд
 - qos .userInitiated занял 1.4220160245895386 секунд
 - qos .userInteractive занял 1.5229049921035767 секунд
 
 Фильтр sepia(intensity: 1.0):
 - qos .utility занял 1.4851679801940918 секунд
 - qos .background занял 7.634137988090515 секунд
 - qos .default занял 1.439507007598877 секунд
 - qos .userInitiated занял 1.4385349750518799 секунд
 - qos .userInteractive) занял 1.4506620168685913 секунд
 
 Фильтр chrome:
 - qos .utility занял 1.4581190347671509 секунд
 - qos .background занял 7.7738200426101685 секунд
 - qos .default занял 1.4733970165252686 секунд
 - qos .userInitiated занял 1.4715501070022583 секунд
 - qos userInteractive занял 1.469506025314331 секунд
*/
}

extension PhotosViewController: UICollectionViewDataSource {
   
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        processedImages.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PhotosCollectionViewCell.reuseId,
            for: indexPath
        ) as! PhotosCollectionViewCell
        
        let image = processedImages[indexPath.item]
        cell.configure(with: image)
                        
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


