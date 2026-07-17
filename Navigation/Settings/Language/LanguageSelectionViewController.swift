import UIKit

/// Экран выбора языка приложения.
final class LanguageSelectionViewController: UITableViewController {
    
    enum Constants {
        static let cellIdentifier = "LanguageCell"
    }
    
    /// ViewModel, которая содержит список языков и текущий выбор.
    private let viewModel: LanguageSelectionViewModel
    
    init(viewModel: LanguageSelectionViewModel) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Язык приложения"
        view.backgroundColor = .appBackground
        
        configureTableView()
        
    }
    
    /// Регистрация ячеек и базовые настройки таблицы.
    private func configureTableView() {
        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: Constants.cellIdentifier
        )
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        viewModel.itemsCount
    }
    
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Constants.cellIdentifier,
            for: indexPath
        )
        
        let index = indexPath.row
        cell.textLabel?.text = viewModel.title(at: index)
        cell.accessoryType = viewModel.isSelected(at: index) ? .checkmark : .none
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let index = indexPath.row
        viewModel.didSelectItem(at: index)
        
        // Обновить чекмарки после смены языка
        tableView.reloadData()
    }
}
