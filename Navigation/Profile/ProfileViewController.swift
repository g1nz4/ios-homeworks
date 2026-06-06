import UIKit
import StorageService

final class ProfileViewController: UIViewController {
    
    weak var coordinator: ProfileCoordinator?
    var onShowPhotos: (() -> Void)?
    
    private var viewModel: (ProfileViewModelInput & ProfileViewModelOutput)
    private let headerView = ProfileHeaderView()
    
    private lazy var tableView: UITableView = {
        let table = UITableView.init(
            frame: .zero,
            style: .plain
        )
        table.translatesAutoresizingMaskIntoConstraints = false
 
        return table
    }()
    
    init(viewModel: ProfileViewModelInput & ProfileViewModelOutput) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("profile_title", comment: "Заголовок экрана профиля")
        view.backgroundColor = .appBackground
        setupNavigationBar()
        setupTableView()
        tuneTableView()
        bindingViewModel()
        viewModel.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("profile_logout_button", comment: "Кнопка выхода из профиля"),
            style: .plain,
            target: self,
            action: #selector(logoutTapped)
        )
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .appBackground
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.appPrimaryText
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .appAccent
    }

    private func setupTableView() {
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate(
            [
                tableView.leadingAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.leadingAnchor
                ),
                tableView.trailingAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.trailingAnchor
                ),
                tableView.topAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.topAnchor
                ),
                tableView.bottomAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.bottomAnchor
                )
            ]
        )
    }
    
    private func tuneTableView() {
       tableView.register(
           PostTableViewCell.self,
           forCellReuseIdentifier: PostTableViewCell.reuseId
       )
       tableView.register(
           PhotosTableViewCell.self,
           forCellReuseIdentifier: PhotosTableViewCell.reuseId
       )
       tableView.backgroundColor = .appBackground
       tableView.separatorColor = .appSeparator
       tableView.dataSource = self
       tableView.delegate = self
    
        tableView.dragInteractionEnabled = true
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        
       headerView.frame = CGRect(
        x: 0,
        y: 0,
        width: tableView.bounds.width,
        height: 220
       )
       tableView.tableHeaderView = headerView
       headerView.onStatusChangeTap = { [weak self] text in
           self?.viewModel.updateStatus(text)
       }
    }
    
    private func bindingViewModel() {
        viewModel.updateHeader = { [weak self] user in
            self?.headerView.configureUI(user: user)
        }
        viewModel.updatePosts = { [weak self] in
            self?.tableView.reloadData()
        }
        viewModel.showPhotos = { [weak self] in
            self?.onShowPhotos?()
        }
        viewModel.onError = { [weak self] error in
            guard let self = self else { return }
            
            let message = error.rawValue
            let alert = UIAlertController(
                title: "Ошибка",
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
        viewModel.onStatusChanged = { [weak self] newStatus in
            self?.headerView.setStatusLabelText(newStatus)
        }
    }
    
    @objc private func logoutTapped() {
        coordinator?.didTapLogout()
    }
}

extension ProfileViewController: UITableViewDataSource {
    
    func numberOfSections(
        in tableView: UITableView
    ) -> Int {
        viewModel.numberOfSections()
    }
    
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        viewModel.numberOfRows(in: section)
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        switch viewModel.cellType(for: indexPath.section) {
        case .photos:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: PhotosTableViewCell.reuseId,
                for: indexPath
            ) as? PhotosTableViewCell else {
                fatalError("could not dequeueReusableCell")
            }
                return cell
        case .posts:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: PostTableViewCell.reuseId,
                for: indexPath
            ) as? PostTableViewCell else {
                fatalError("could not dequeueReusableCell")
            }
            if let post = viewModel.post(section: indexPath.section, row: indexPath.row){
                let isFavorite = viewModel.isFavorite(postID: post.id)
                cell.setupCell(post: post, isFavorite: isFavorite)
            }
            cell.delegate = self
            return cell
        case .none:
            return UITableViewCell()
        }
    }
}
    
extension ProfileViewController: UITableViewDelegate {
    
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        viewModel.didSelectRow(section: indexPath.section, row: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ProfileViewController: PostTableViewCellDelegate {
    
    func postDidDoubleTap(_ cell: PostTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell),
              let post = viewModel.post(section: indexPath.section, row: indexPath.row)
        else { return }
        
        viewModel.didDoubleTap(post: post)
    }
}

extension ProfileViewController: UITableViewDragDelegate {

    func tableView(
        _ tableView: UITableView,
        itemsForBeginning session: UIDragSession,
        at indexPath: IndexPath
    ) -> [UIDragItem] {

        guard viewModel.cellType(for: indexPath.section) == .posts,
              let post = viewModel.post(section: indexPath.section, row: indexPath.row)
        else { return [] }

        let imageProvider = NSItemProvider(object: post.image)
        let imageItem = UIDragItem(itemProvider: imageProvider)
        imageItem.localObject = post

        let description = post.description as NSString
        let textProvider = NSItemProvider(object: description)
        let textItem = UIDragItem(itemProvider: textProvider)

        return [imageItem, textItem]
    }
}

extension ProfileViewController: UITableViewDropDelegate {
    
    func tableView(
        _ tableView: UITableView,
        canHandle session: UIDropSession
    ) -> Bool {
        let canLoadImage = session.canLoadObjects(ofClass: UIImage.self)
        let canLoadText  = session.canLoadObjects(ofClass: NSString.self)
        
        return canLoadImage || canLoadText
    }
    
    func tableView(
        _ tableView: UITableView,
        dropSessionDidUpdate session: UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?
    ) -> UITableViewDropProposal {
        let operation: UIDropOperation = (session.localDragSession == nil) ? .copy : .move
        
        let intent: UITableViewDropProposal.Intent = destinationIndexPath == nil ? .unspecified : .insertAtDestinationIndexPath
        
        return UITableViewDropProposal(operation: operation, intent: intent)
    }
    
    func tableView(
        _ tableView: UITableView,
        performDropWith coordinator: UITableViewDropCoordinator
    ) {
        let postsSection = sectionIndexForPosts()
        
        let destinationIndexPath: IndexPath = {
            if let indexPath = coordinator.destinationIndexPath {
                let row = min(max(indexPath.row, 0), viewModel.numberOfRows(in: postsSection))
                return IndexPath(row: row, section: postsSection)
            } else {
                let rows = viewModel.numberOfRows(in: postsSection)
                return IndexPath(row: rows, section: postsSection)
            }
        }()
        
        let session = coordinator.session
        
        session.loadObjects(ofClass: UIImage.self) { [weak self] imagesAny in
            guard let self else { return }
            
            let images = imagesAny as? [UIImage] ?? []
            
        session.loadObjects(ofClass: NSString.self) { [weak self] stringsAny in
            guard let self else { return }
            
            let strings = stringsAny as? [NSString] ?? []
        
            if images.isEmpty && strings.isEmpty { return }
            
                let image: UIImage = images.first ?? UIImage()
                let description: String = (strings.first as String?) ?? "Drag & Drop post"
                let newPost = MyPost(
                    id: UUID().uuidString,
                    author: "Drag&Drop",
                    image: image,
                    description: description,
                    likes: 0,
                    views: 0
                )
                
                DispatchQueue.main.async {
                    self.viewModel.insert(post: newPost, at: destinationIndexPath.row)
                    self.tableView.scrollToRow(
                        at: destinationIndexPath,
                        at: .middle,
                        animated: true
                    )
                }
            }
        }
    }
    
    private func sectionIndexForPosts() -> Int {
        let sections = viewModel.numberOfSections()
        
        for section in 0..<sections {
            if viewModel.cellType(for: section) == .posts { return section }
        }
        
        return 2
    }
}
