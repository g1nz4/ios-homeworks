import UIKit
import StorageService

final class ProfileViewController: UIViewController {
    
    fileprivate let posts = MyPost.make()
    
    private lazy var tableView: UITableView = {
        let table = UITableView.init(
            frame: .zero,
            style: .plain
        )
        table.translatesAutoresizingMaskIntoConstraints = false
 
        return table
    }()
    
    var user: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: true)
        tuneTableView()
        setupTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
        #if DEBUG
            view.backgroundColor = UIColor.systemYellow
        #else
            view.backgroundColor = UIColor.systemCyan
        #endif
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
       tableView.backgroundColor = UIColor(named: "Color")
       tableView.dataSource = self
       tableView.delegate = self
    
       let header = ProfileHeaderView()
       header.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 220)
       if let user = user {
           header.configureUI(user: user)
       }
       tableView.tableHeaderView = header
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
    
}

extension ProfileViewController: UITableViewDataSource {
    
    func numberOfSections(
        in tableView: UITableView
    ) -> Int {
        3
    }
    
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        if section == 0 {
            return 0
        } else if section == 1 {
            return 1
        } else if section == 2 {
            return posts.count
        }
        return 0
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        if indexPath.section == 1  {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: PhotosTableViewCell.reuseId,
                for: indexPath
            ) as? PhotosTableViewCell else {
                fatalError("could not dequeueReusableCell")
            }
                return cell
            }
        
         if indexPath.section == 2 {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: PostTableViewCell.reuseId,
                for: indexPath
            ) as? PostTableViewCell else {
                fatalError("could not dequeueReusableCell")
            }
            let post = posts[indexPath.row]
            cell.setupCell(post: post)
           
            return cell
        }
         return UITableViewCell()
    }
}
    
extension ProfileViewController: UITableViewDelegate {
    
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        if indexPath.section == 1 && indexPath.row == 0 {
            navigationController?.pushViewController(PhotosViewController(), animated: true)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}

