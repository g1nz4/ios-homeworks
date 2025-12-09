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
    
    private func tuneTableView() {
           tableView.register(
               PostTableViewCell.self,
               forCellReuseIdentifier: PostTableViewCell.reuseId
           )
           
           tableView.register(
               ProfileTableHeaderView.self,
               forHeaderFooterViewReuseIdentifier: ProfileTableHeaderView.headerReuseId
           )
           tableView.sectionHeaderHeight = 220.0
           tableView.dataSource = self
           tableView.delegate = self
       }
}

extension ProfileViewController: UITableViewDataSource {
    
    func numberOfSections(
        in tableView: UITableView
    ) -> Int {
        1
    }
    
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        posts.count
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: PostTableViewCell.reuseId,
            for: indexPath
        ) as? PostTableViewCell {
            let post = posts[indexPath.row]
            cell.setupCell(post: post)
            
            return cell
        } else {
            return UITableViewCell()
        }
    }
}
extension ProfileViewController: UITableViewDelegate {
    
    func tableView(
        _ tableView: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView? {
        if section == 0 {
            let view = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: ProfileTableHeaderView.headerReuseId
            ) as! ProfileTableHeaderView
            
            return view
        } else {
            fatalError("could not dequeueReusableCell")
        }
    }
}
