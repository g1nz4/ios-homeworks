import UIKit

/// Кнопка основного действия с единым стилем для всего приложения.
/// Поддерживает состояние загрузки (индикатор вместо текста) и callback по нажатию.
final class PrimaryActionButton: UIButton {
   
    // Индикатор активности, показывается поверх кнопки во время загрузки
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
   
    // Замыкание, вызываемое при нажатии на кнопку
    private var tapAction: (() -> Void)?
    
    // Сохранённый текст кнопки, чтобы вернуть его после завершения загрузки
    private var storedTitle: String?
    
    // Флаг "идёт загрузка", при изменении автоматически обновляет внешний вид
    var isLoading: Bool = false {
        didSet { updateLoadingState() }
    }
   
    // При изменении isEnabled изменяет прозрачность
    override var isEnabled: Bool {
        didSet { updateAlpha() }
    }
    
    // При нажатии меняет alpha для эффекта нажатия
    override var isHighlighted: Bool {
        didSet { updateAlpha() }
    }
    
    init(
        title: String,
        tapAction: (() -> Void)? = nil
    ) {
        self.tapAction = tapAction
        super.init(frame: .zero)
        configureAppearance()
        setTitle(title, for: .normal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Позволяет задать/переопределить действие по нажатию в любой момент.
    func setAction(_ action: @escaping () -> Void) {
        self.tapAction = action
    }
    
    /// Общая настройка внешнего вида кнопки и сабвью.
    private func configureAppearance() {
        translatesAutoresizingMaskIntoConstraints = false
        
        let image = UIImage(named: "blue_pixel.png")
        setBackgroundImage(image, for: .normal)
        
        setTitleColor(.appButtonText, for: .normal)
        titleLabel?.font = UIFont.preferredFont(forTextStyle: .footnote).withSize(16.0)
        
        layer.cornerRadius = 10.0
        clipsToBounds = true
        
        // Типовая высота кнопки
        heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .appAccent
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        updateAlpha()
    }
    
    /// Обновление состояния кнопки в зависимости от флага isLoading.
    private func updateLoadingState() {
        if isLoading {
            storedTitle = title(for: .normal)
            setTitle(nil, for: .normal)
            isEnabled = false
            activityIndicator.startAnimating()
        } else {
            if let storedTitle {
                setTitle(storedTitle, for: .normal)
            }
            activityIndicator.stopAnimating()
            isEnabled = true
        }
    }
    
    /// Обновляет прозрачность кнопки в зависимости от состояния.
    private func updateAlpha() {
        if !isEnabled {
            alpha = 0.7
        } else if isHighlighted {
            alpha = 0.8
        } else {
            // normal
            alpha = 1.0
        }
    }

    /// Обработчик нажатия на кнопку. Если сейчас идёт загрузка —  нажатие игнорируется.
    @objc private func handleTap() {
        guard !isLoading else { return }
        tapAction?()
    }
}

