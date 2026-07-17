import UIKit

/// Экран настроек приложения.
@MainActor
final class SettingsTableViewController: UITableViewController {
    
    /// ViewModel, отвечающая за бизнес‑логику и подготовку данных для таблицы.
    private let viewModel: SettingsViewModel
    /// Текущие данные для отображения.
    private var sections: [SettingsSectionViewData] = []
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Настройки"
        view.backgroundColor = .appBackground
        
        configureTableView()
        bindViewModel()
        configureNotifications()
        
        // Первый запрос данных
        Task { [weak self] in
            await self?.viewModel.load()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Регистрация ячеек, настройка таблицы.
    private func configureTableView() {
        tableView.register(
            SettingsSwitchCell.self,
            forCellReuseIdentifier: SettingsSwitchCell.reuseId
        )
        
        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: "basic"
        )
    }
    
    /// Привязка выходов ViewModel к обновлению UI и навигации.
    private func bindViewModel() {
        // Обновление данных таблицы
        viewModel.outputs.onDataChanged = { [weak self] sections in
            self?.sections = sections
            self?.tableView.reloadData()
        }
        
        // Открытие системных настроек приложения
        viewModel.outputs.onOpenSystemSettings = { _ in
            UIApplication.openAppSettings()
        }
        
        // Показ алерта, если системное разрешение отключено
        viewModel.outputs.onPermissionDeniedAlert = { [weak self] kind in
            self?.presentPermissionDeniedAlert(for: kind)
        }
    }
    
    /// Подписка на системные нотификации.
    /// В данном случае — на возвращение приложения в активное состояние, чтобы актуализировать статусы разрешений.
    private func configureNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    /// Обработчик события, когда приложение стало активным.
    /// Используется  для повторной загрузки данных настроек, чтобы отразить изменения системных разрешений, сделанные пользователем в настройках iOS.
    @objc private func appDidBecomeActive() {
        Task { [weak self] in
            await self?.viewModel.load()
        }
    }
    
    /// Показывает алерт о том, что соответствующее разрешение отключено, с предложением открыть системные настройки.
    private func presentPermissionDeniedAlert(for kind: PermissionKind) {
        let title: String
        let message: String
        
        switch kind {
        case .notifications:
            title = "Уведомления отключены"
            message = "Разрешите уведомления в настройках системы."
        case .camera:
            title = "Нет доступа к камере"
            message = "Разрешите доступ к камере в настройках системы."
        case .photos:
            title = "Нет доступа к фото"
            message = "Разрешите доступ к фото в настройках системы."
        }
        
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(
            UIAlertAction(title: "Отмена", style: .cancel)
        )
        
        alert.addAction(
            UIAlertAction(
                title: "Открыть настройки",
                style: .default
            ) { _ in
                UIApplication.openAppSettings()
            }
        )
        
        present(alert, animated: true)
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }
    
    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        sections[section].rows.count
    }
    
    override func tableView(
        _ tableView: UITableView,
        titleForHeaderInSection section: Int
    ) -> String? {
        sections[section].title
    }
    
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        
        switch row.id {
        case .theme, .language:
            // Обычная basic‑ячейка со стрелкой перехода
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "basic",
                for: indexPath
            )
            
            cell.textLabel?.text = row.title
            cell.detailTextLabel?.text = row.detail
            cell.accessoryType = .disclosureIndicator
            return cell
            
        default:
            // Ячейка с UISwitch или обычная basic‑ячейка
            if row.isSwitch {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: SettingsSwitchCell.reuseId,
                    for: indexPath
                ) as! SettingsSwitchCell
                
                cell.configure(title: row.title, isOn: row.isOn)
                cell.onToggle = { [weak self] isOn in
                    guard let self else { return }
                    Task {
                        await self.viewModel.didToggleSwitch(for: row.id, isOn: isOn)
                    }
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: "basic",
                    for: indexPath
                )
                
                cell.textLabel?.text = row.title
                cell.detailTextLabel?.text = row.detail
                cell.accessoryType = row.showsDisclosure ? .disclosureIndicator : .none
                return cell
            }
        }
    }
    
    // MARK: - Footer
    
    override func tableView(
        _ tableView: UITableView,
        viewForFooterInSection section: Int
    ) -> UIView? {
        guard let footerData = sections[section].footer else {
            return nil
        }
        
        let footer = NotificationsFooterView()
        footer.configure(
            text: footerData.text,
            buttonTitle: footerData.buttonTitle ?? ""
        )
        
        footer.onTap = { [weak self] in
            guard let self else { return }
            let sectionID = self.sections[section].id
            self.viewModel.didTapFooterButton(for: sectionID)
        }
        
        return footer
    }
    
    override func tableView(
        _ tableView: UITableView,
        heightForFooterInSection section: Int
    ) -> CGFloat {
        sections[section].footer == nil
        ? .leastNormalMagnitude
        : UITableView.automaticDimension
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = sections[indexPath.section].rows[indexPath.row]
        viewModel.didSelectRow(row.id)
    }
}
