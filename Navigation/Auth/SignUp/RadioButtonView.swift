import UIKit

/// Кастомный UIControl, реализующий радио‑кнопку с текстом справа
final class RadioButtonView: UIControl {

    /// Текущее состояние радио‑кнопки.
    var isOn: Bool = false {
        didSet { updateAppearance(animated: true) }
    }

    /// Текст рядом с кружком
    var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }
    
    /// Цвет активного состояния
    var activeColor: UIColor = .appAccent
    /// Цвет неактивного состояния
    var inactiveColor: UIColor = .appSecondaryText
    
    /// Базовый размер контрола (для автолейаута, когда нет явных констрейнтов).
    override var intrinsicContentSize: CGSize {
        let labelSize = titleLabel.intrinsicContentSize
        let width = 18 + 8 + labelSize.width     // кружок + отступ + текст
        let height = max(18, labelSize.height)
        return CGSize(width: width, height: height)
    }
    
    /// Внешний кружок (контур радио‑кнопки)
    private lazy var outerCircle: UIView = {
        let view = UIView()
        view.layer.borderWidth = 2
        view.layer.masksToBounds = true
        view.isUserInteractionEnabled = false
        
        return view
    }()

    /// Внутренний кружок (точка), видна только в состоянии isOn == true
    private lazy var innerCircle: UIView = {
        let view = UIView()
        view.layer.masksToBounds = true
        view.isUserInteractionEnabled = false
        
        return view
    }()

    /// Лейбл с текстом справа от кружка
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = UIColor.appPrimaryText
        
        return label
    }()
   
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureUI()
        updateAppearance(animated: false)
        
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Обновить скругление углов кружков после того, как у них появились размеры
    override func layoutSubviews() {
        super.layoutSubviews()
        outerCircle.layer.cornerRadius = outerCircle.bounds.height / 2
        innerCircle.layer.cornerRadius = innerCircle.bounds.height / 2
    }
    
    /// Расширение tappable‑область, чтобы по контролу было легче попасть
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let expandedBounds = bounds.insetBy(dx: -10, dy: -10)
        
        return expandedBounds.contains(point)
    }

    /// Конфигурация и раскладка сабвью
    private func configureUI() {
        [outerCircle, innerCircle,titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            outerCircle.leadingAnchor.constraint(equalTo: leadingAnchor),
            outerCircle.centerYAnchor.constraint(equalTo: centerYAnchor),
            outerCircle.widthAnchor.constraint(equalToConstant: 18),
            outerCircle.heightAnchor.constraint(equalToConstant: 18),

            innerCircle.centerXAnchor.constraint(equalTo: outerCircle.centerXAnchor),
            innerCircle.centerYAnchor.constraint(equalTo: outerCircle.centerYAnchor),
            innerCircle.widthAnchor.constraint(equalToConstant: 10),
            innerCircle.heightAnchor.constraint(equalToConstant: 10),

            titleLabel.leadingAnchor.constraint(equalTo: outerCircle.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            heightAnchor.constraint(equalTo: outerCircle.heightAnchor)
        ])
    }

    private func updateAppearance(animated: Bool) {
        let changes = {
            self.outerCircle.layer.borderColor =
                (self.isOn ? self.activeColor : self.inactiveColor).cgColor
            self.innerCircle.backgroundColor = self.isOn ? self.activeColor : .clear
        }

        if animated {
            UIView.animate(withDuration: 0.15, animations: changes)
        } else {
            changes()
        }
    }

    @objc private func handleTap() {
        sendActions(for: .valueChanged)
    }
}
