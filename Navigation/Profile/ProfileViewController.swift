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
            title: "Выйти",
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
