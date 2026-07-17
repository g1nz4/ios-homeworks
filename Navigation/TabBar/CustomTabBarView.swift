import UIKit

/// Кастомный таббар для корневого контейнера. Показывает только иконки (SF Symbols), без текста.
final class CustomTabBarView: UIView {
    
    /// Вызывается при выборе вкладки по индексу.
    var onSelectIndex: ((Int) -> Void)?
    
    private let stack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        
        return stack
    }()
    
    /// Кнопки таббара, соответствуют `items` по индексу.
    private var buttons: [UIButton] = []
    
    /// Модельные элементы таббара.
    private var items: [TabItem] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Базовая настройка внешнего вида и layout-а.
    private func setupView() {
        backgroundColor = .appTabBarBackground
        addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 6.0),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    /// Конфигурирует таббар набором items.
    func configure(with items: [TabItem]) {
        self.items = items
        
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()
        
        // Создать кнопку под каждый item
        for (index, item) in items.enumerated() {
            let button = makeButton(for: item, index: index)
            buttons.append(button)
            stack.addArrangedSubview(button)
        }
        
        // Вкладку по умолчанию - профиль
        setSelected(index: 2)
    }
    
    /// Создаёт и настраивает кнопку по модели TabItem.
    private func makeButton(for item: TabItem, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.tag = index
        
        let image = UIImage(
            systemName: item.systemImageName,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        )
        button.setImage(image, for: .normal)
        button.tintColor = .appSecondaryText
        
        button.addTarget(self, action: #selector(didTap(_:)), for: .touchUpInside)
        return button
    }
    
    /// Обновляет вид кнопок с учётом выбранного индекса.
    func setSelected(index: Int) {
        for (i, b) in buttons.enumerated() {
            let selected = (i == index)
            b.tintColor = selected ? .appAccent : .appSecondaryText
        }
    }
    
    @objc private func didTap(_ sender: UIButton) {
        onSelectIndex?(sender.tag)
    }
}
