import UIKit

final class FeedView: UIView {
    
    var tappedOnButton: ((String) -> Void)?
    
    private lazy var resultLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16.0, weight: .regular)
        label.textAlignment = .center
        
        return label
    }()
    
    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Введите слово"
        textField.borderStyle = .roundedRect
        textField.textColor = .label
       
        return textField
    }()
    
    private lazy var checkGuessButton = CustomButton(
        title: "Проверить слово"
    ){ [weak self] in
        self?.tappedOnCheckButton()
    }
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            resultLabel,
            textField,
            checkGuessButton
        ])
        stack.clipsToBounds = true
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 10.0
        
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showResult(isCorrect: Bool) {
        if isCorrect {
            resultLabel.text = "Верно!"
            resultLabel.textColor = .systemGreen
        } else {
            resultLabel.text = "Неверно!"
            resultLabel.textColor = .systemRed
        }
    }
    
    func showEmptyTextField() {
        resultLabel.text = "Введите слово"
        resultLabel.textColor = .systemBlue
    }
    
    private func setupView() {
        [resultLabel, textField, checkGuessButton, stackView].forEach() {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            resultLabel.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            resultLabel.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            resultLabel.heightAnchor.constraint(equalToConstant: 30.0),
            
            textField.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            textField.heightAnchor.constraint(equalToConstant: 40.0),
            
            checkGuessButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            checkGuessButton.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            checkGuessButton.heightAnchor.constraint(equalToConstant: 50.0)
        ])
    }
    
    private func tappedOnCheckButton() {
        let text = textField.text ?? ""
        tappedOnButton?(text)
    }
}
