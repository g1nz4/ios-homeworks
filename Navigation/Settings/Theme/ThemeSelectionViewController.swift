import UIKit

/// Экран выбора темы оформления приложения.
final class ThemeSelectionViewController: UITableViewController {
    
    enum Constants {
        static let cellIdentifier = "ThemeCell"
    }
    
    /// ViewModel, которая управляет текущей темой и списком доступных тем.
    private let viewModel: ThemeSelectionViewModel
    
    init(viewModel: ThemeSelectionViewModel) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Тема"
        configureTableView()
    }
    /// Регистрация ячейки таблицы.
    private func configureTableView() {
        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: Constants.cellIdentifier
        )
    }
    
    // MARK: - DataSource
    
    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        viewModel.items.count
    }
    
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Constants.cellIdentifier,
            for: indexPath
        )
        let theme = viewModel.items[indexPath.row]
        cell.textLabel?.text = title(for: theme)
        cell.accessoryType = (theme == viewModel.currentTheme) ? .checkmark : .none
        
        return cell
    }
    
    // MARK: - Delegate
    
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.didSelectTheme(at: indexPath.row)
        
        // Обновить чекмарки после смены темы
        tableView.reloadData()
    }
    
    // MARK: - Helpers
    
    private func title(for theme: AppTheme) -> String {
        switch theme {
        case .system:
            return "Системная"
        case .light:  
            return "Светлая"
        case .dark:   
            return "Тёмная"
        }
    }
}
