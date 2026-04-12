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
        setupNavigationBar()
        tableView.register(
            PostTableViewCell.self,
            forCellReuseIdentifier: PostTableViewCell.reuseId
        )
        addObserver()
        loadFavorites()
    }

    private func setupNavigationBar() {
        let searchItem = UIBarButtonItem(
            image: UIImage(systemName: "magnifyingglass"),
            style: .plain,
            target: self,
            action: #selector(searchTapped)
        )
        
        let resetItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark.circle"),
            style: .plain,
            target: self,
            action: #selector(resetTapped)
        )
        
        navigationItem.rightBarButtonItems = [resetItem, searchItem]
    }
    
    private func applySearch(author: String) {
        Task { [weak self] in
            guard let self else { return }
           
            do {
                try await viewModel.search(by: author)
                if viewModel.numberOfRows() == 0 {
                    self.showMessage("Автор \"\(author)\" не найден.")
                }
                self.tableView.reloadData()
            } catch {
                self.showMessage("\(error.localizedDescription)")
            }
        }
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
        let action = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(action)
        present(alert, animated: true)
    }

    @objc private func favoritesDidChange() {
        loadFavorites()
    }
    
    @objc private func searchTapped() {
        let alert = UIAlertController(
            title: "Поиск по автору",
            message: nil,
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = "Введите имя автора"
        }
        let apply = UIAlertAction(
            title: "Применить",
            style: .default
        ) { [weak self] _ in
            guard let self else { return }
            guard let text = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !text.isEmpty else { return }
            self.applySearch(author: text)
        }
        
        let cancel = UIAlertAction(
            title: "Отмена",
            style: .cancel
        )
        alert.addAction(apply)
        alert.addAction(cancel)
        
        present(alert, animated: true)
    }
    
    @objc private func resetTapped() {
        Task { [weak self] in
            guard let self else { return }
            
            do {
                try await viewModel.resetFilter()
                self.tableView.reloadData()
            } catch {
                self.showMessage("\(error.localizedDescription)")
            }
        }
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
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(
            style: .destructive,
            title: "Удалить") { [weak self] _, _, completion in
                guard let self else {
                    completion(false)
                    return
                }
                
                Task {
                    do {
                        try await self.viewModel.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                        NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
                        completion(true)
                    } catch {
                        self.showMessage("\(error.localizedDescription)")
                        completion(false)
                    }
                }
            }
        
        let config = UISwipeActionsConfiguration(actions: [action])
        config.performsFirstActionWithFullSwipe = true
        
        return config
    }
}
