import UIKit
import CoreData
import StorageService

class FavoritesTableViewController: UITableViewController {

    private var fetchedResultsController: NSFetchedResultsController<FavoritePost>?
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Избранное"
        tableView.register(
            PostTableViewCell.self,
            forCellReuseIdentifier: PostTableViewCell.reuseId
        )
        setupNavigationBar()
        configureFetchedResultsController()
    }
    
    private func configureFetchedResultsController(searchAuthor: String? = nil) {
        let context = CoreDataStack.shared.viewContext
        let request: NSFetchRequest<FavoritePost> = FavoritePost.fetchRequest()
        
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        
        if let author = searchAuthor, !author.isEmpty {
            request.predicate = NSPredicate(format: "author CONTAINS[c] %@", author)
        }
        
        let controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller.delegate = self
        fetchedResultsController = controller
        
        do {
            try controller.performFetch()
            tableView.reloadData()
        } catch {
            showMessage("Ошибка загрузки данных: \(error.localizedDescription)")
        }
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
            self.configureFetchedResultsController(searchAuthor: text)
            
            if (self.fetchedResultsController?.fetchedObjects?.isEmpty ?? true) {
                self.showMessage("Автор \"\(text)\" не найден.")
            }
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
        configureFetchedResultsController(searchAuthor: nil)
    }
    
    override func numberOfSections(
        in tableView: UITableView
    ) -> Int {
        return fetchedResultsController?.sections?.count ?? 0
    }

    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return fetchedResultsController?.sections?[section].numberOfObjects ?? 0
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
        
        if let favoritePost = fetchedResultsController?.object(at: indexPath) {
            if let post = CoreDataManager.mapFavoritePost(favoritePost) {
                cell.setupCell(post: post, isFavorite: false)
            }
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
                guard let self,
                      let frc = self.fetchedResultsController else {
                    completion(false)
                    return
                }
                
                let objectID = frc.object(at: indexPath).objectID
                
                Task { [weak self] in
                    guard let self else {
                           completion(false)
                           return
                       }
                    
                    do {
                        let context = CoreDataStack.shared.newBackgroundContext()
                        try await context.perform{
                            if let obj = try context.existingObject(with: objectID) as? FavoritePost {
                                context.delete(obj)
                                if context.hasChanges {
                                    try context.save()
                                }
                            }
                        }
                        await MainActor.run {
                            NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
                        }
                        completion(true)
                    } catch {
                        await MainActor.run {
                            self.showMessage("Ошибка удаления: \(error.localizedDescription)")
                        }
                        completion(false)
                    }
                }
            }
        
        let config = UISwipeActionsConfiguration(actions: [action])
        config.performsFirstActionWithFullSwipe = true
        
        return config
    }
}

extension FavoritesTableViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    ) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    ) {
        tableView.endUpdates()
    }
    
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        switch type {
        case .insert:
            if let newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
            
        case .delete:
            if let indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            
        case .update:
            if let indexPath,
               let cell = tableView.cellForRow(at: indexPath) as? PostTableViewCell,
               let favoritePost = fetchedResultsController?.object(at: indexPath),
               let post = CoreDataManager.mapFavoritePost(favoritePost) {
                cell.setupCell(post: post, isFavorite: false)
            }
            
        case .move:
            if let indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            if let newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
            
        @unknown default:
            break
        }
    }
}
