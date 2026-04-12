import UIKit
import StorageService

class FavoritesTableViewController: UITableViewController {

    private var viewModel: FavoritesViewModelProtocol
    
    init(viewModel: FavoritesViewModelProtocol = FavoritesViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Избранное"
        tableView.register(
            PostTableViewCell.self,
            forCellReuseIdentifier: PostTableViewCell.reuseId
        )
        addObserver()
        loadFavorites()
    }

    private func addObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(favoritesDidChange),
            name: .favoritesDidChange,
            object: nil
        )
    }
    
    private func loadFavorites() {
        Task { [weak self] in
            guard let self else { return }
            
            do {
                try await viewModel.loadFavorites()
                self.tableView.reloadData()
            } catch {
                self.showMessage("\(error.localizedDescription)")
            }
        }
    }
    
    private func showMessage(_ message: String) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: message,
            preferredStyle: .alert
        )
        let action = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(action)
        present(alert, animated: true)
    }

    @objc private func favoritesDidChange() {
        loadFavorites()
    }
    
    override func numberOfSections(
        in tableView: UITableView
    ) -> Int {
        return 1
    }

    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return viewModel.numberOfRows()
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: PostTableViewCell.reuseId,
            for: indexPath
        ) as? PostTableViewCell else {
            fatalError("could not dequeueReusableCell")
        }
        if let post = viewModel.post(at: indexPath.row) {
            cell.setupCell(post: post)
        }

        return cell
    }

    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        guard editingStyle == .delete else { return }
        
        Task { [weak self] in
            guard let self else { return }
            
            do {
                try await viewModel.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
            } catch {
                self.showMessage("\(error.localizedDescription)")
            }
        }
    }
}
