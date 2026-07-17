import UIKit

/// Ячейка таблицы с подписью и UISwitch справа. Используется на экране настроек для переключаемых опций.
final class SettingsSwitchCell: UITableViewCell {

    /// Идентификатор переиспользования для регистрации в таблице.
    static let reuseId = "SettingsSwitchCell"

    /// Колбэк, который вызывается при изменении состояния переключателя. Передаёт новое состояние `isOn`.
    var onToggle: ((Bool) -> Void)?

    /// Заголовок настройки.
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .appPrimaryText
        
        return label
    }()

    /// Переключатель (UISwitch) справа.
    private lazy var toggleSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = .appAccent
        toggle.addTarget(
            self,
            action: #selector(didChangeSwitch),
            for: .valueChanged
        )
        return toggle
    }()


    override init(
        style: UITableViewCell.CellStyle,
        reuseIdentifier: String?
    ) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    /// Базовая настройка внешнего вида ячейки.
    private func configureUI() {
        selectionStyle = .none
        
        [titleLabel, toggleSwitch].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            toggleSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            toggleSwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    /// Конфигурирование содержимого ячейки.
    func configure(title: String, isOn: Bool) {
        titleLabel.text = title
        toggleSwitch.isOn = isOn
    }

    /// Обработчик изменения состояния переключателя. Вызывает колбэк `onToggle` с новым значением `isOn`.
    @objc private func didChangeSwitch() {
        onToggle?(toggleSwitch.isOn)
    }
}
