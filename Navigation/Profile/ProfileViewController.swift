import UIKit

class ProfileViewController: UIViewController {
    
    fileprivate let posts = MyPost.make()
    
    private lazy var tableView: UITableView = {
        let table = UITableView.init(
            frame: .zero,
            style: .plain
        )
        table.translatesAutoresizingMaskIntoConstraints = false
 
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        addSubView()
        tuneTableView()
        setupConstraints()
    }
    
    private func addSubView() {
        view.addSubview(tableView)
    }
    
    private func tuneTableView() {
           tableView.register(
               PostTableViewCell.self,
               forCellReuseIdentifier: PostTableViewCell.reuseId
           )
           tableView.register(
               ProfileTableHeaderView.self,
               forHeaderFooterViewReuseIdentifier: ProfileTableHeaderView.headerReuseId
           )
           tableView.register(
               PhotosTableViewCell.self,
               forCellReuseIdentifier: PhotosTableViewCell.reuseId
           )
           tableView.backgroundColor = UIColor(named: "Color")
           tableView.dataSource = self
           tableView.delegate = self
    }
    
    private func setupConstraints() {
        let sefeAreaGuide = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate(
            [
                tableView.leadingAnchor.constraint(
                    equalTo: sefeAreaGuide.leadingAnchor
                ),
                tableView.trailingAnchor.constraint(
                    equalTo: sefeAreaGuide.trailingAnchor
                ),
                tableView.topAnchor.constraint(
                    equalTo: sefeAreaGuide.topAnchor
                ),
                tableView.bottomAnchor.constraint(
                    equalTo: sefeAreaGuide.bottomAnchor
                ),
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
        heightForHeaderInSection section: Int
    ) -> CGFloat {
        if section == 0 {
            tableView.sectionHeaderHeight = 220.0
            tableView.contentInset.top = -20.0
        }
        if section == 1 {
            tableView.sectionHeaderHeight = 0.0
        }
        if section == 2 {
            tableView.sectionHeaderHeight = 0.0
        }
        return tableView.sectionHeaderHeight
    }
    
    func tableView(
        _ tableView: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: ProfileTableHeaderView.headerReuseId
        ) as! ProfileTableHeaderView
        guard section == 0 else {
            return UITableViewHeaderFooterView()
        }
        return view
    }
    
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
