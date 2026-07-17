import UIKit

/// Группа радио‑кнопок для выбора пола.
final class GenderRadioGroupView: UIView {
    
    /// Коллбэк, вызывается при изменении выбранного пола
    var onGenderChanged: ((Gender) -> Void)?
    
    /// Текущий выбранный пол. При изменении обновляем UI и дергаем коллбэк.
    var selectedGender: Gender = .male {
        didSet { updateSelection(animated: true) }
    }
    
    /// Горизонтальный стек с двумя радио‑кнопками: "Мужской" и "Женский"
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [maleButton, femaleButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fillProportionally
        stack.spacing = 10
        
        return stack
    }()
    
    private lazy var maleButton: RadioButtonView = {
        let button = RadioButtonView()
        button.title = Gender.male.localizedTitle
        button.addTarget(self, action: #selector(maleTapped), for: .valueChanged)
        
        return button
    }()
    
    private lazy var femaleButton: RadioButtonView = {
        let button = RadioButtonView()
        button.title = Gender.female.localizedTitle
        button.addTarget(self, action: #selector(femaleTapped), for: .valueChanged)
        
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureUI()
        updateSelection(animated: false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureUI() {
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    private func updateSelection(animated: Bool) {
        let applySelection = { [weak self] in
            guard let self else { return }
            
            switch self.selectedGender {
            case .male:
                self.maleButton.isOn = true
                self.femaleButton.isOn = false
            case .female:
                self.maleButton.isOn = false
                self.femaleButton.isOn = true
            }
        }
        
        if animated {
            UIView.animate(withDuration: 0.15, animations: applySelection)
        } else {
            applySelection()
        }
        
        onGenderChanged?(selectedGender)
    }
    
    @objc private func femaleTapped() {
        guard selectedGender != .female else { return }
        selectedGender = .female
    }
    
    @objc private func maleTapped() {
        guard selectedGender != .male else { return }
        selectedGender = .male
    }
}

