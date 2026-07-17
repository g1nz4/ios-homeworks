import UIKit

/// Универсальный контрол с заголовком и текстовым полем. Используется в формах (регистрация, редактирование данных профиля ...).
final class LabeledTextFieldView: UIView {
    //заголовок
    let titleLabel = UILabel()
    // поле ввода
    let textField = UITextField()
    
    init(
         title: String,
         placeholder: String,
         keyboardType: UIKeyboardType = .default,
         isSecure: Bool = false
    ) {
        super.init(frame: .zero)
        setupUI(
            title: title,
            placeholder: placeholder,
            keyboardType: keyboardType,
            isSecure: isSecure
        )
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI(title: "", placeholder: "")
    }
    
    /// Базовая конфигурация сабвью: лейбл + текстфилд в вертикальном стеке.
    private func setupUI(
        title: String,
        placeholder: String,
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false
    ) {
        translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.text = title
        titleLabel.font = UIFont.preferredFont(forTextStyle: .footnote).withSize(14.0)
        titleLabel.textColor = .appPrimaryText
        
        textField.font = UIFont.preferredFont(forTextStyle: .footnote).withSize(16.0)
        textField.placeholder = placeholder
        textField.borderStyle = .roundedRect
        textField.keyboardType = keyboardType
        textField.isSecureTextEntry = isSecure
        textField.backgroundColor = .appTextFieldBackground
        textField.textColor = .appPrimaryText
        textField.clipsToBounds = true
        textField.layer.cornerRadius = 10.0
        textField.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, textField])
        stack.axis = .vertical
        stack.spacing = 4.0
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
