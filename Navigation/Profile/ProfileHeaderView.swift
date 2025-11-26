import UIKit

class ProfileHeaderView: UIView {
   
    private lazy var avatarImageView: UIImageView = {
         let imageView = UIImageView()
         imageView.image = UIImage(named: "SimpleCat")
         imageView.layer.borderWidth = 3
         imageView.layer.borderColor = (UIColor(white: 242.0/255.0, alpha: 1.0)).cgColor
         imageView.contentMode = .scaleAspectFit
         imageView.clipsToBounds = true
         imageView.layer.cornerRadius = 60
         
         return imageView
    }()
    
    private lazy var fullNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Cat Developer"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .black
      
        return label
    }()
    
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.text = "I'm cat ios-developer :)"
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .systemGray
        
        return label
    }()
    
    private lazy var setStatusButton: UIButton = {
       let button = UIButton()
        button.setTitle("Show Status", for: .normal)
        button.layer.shadowOffset = CGSize(width: 4.0, height: 4.0)
        button.layer.shadowRadius = 4.0
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.7
        button.layer.backgroundColor = UIColor.systemBlue.cgColor
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 4
        button.addTarget(self, action: #selector (buttonTaped(_ :)), for: .touchUpInside)
        
        return button
    }()
    
    private lazy var statusTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = " Введите..."
        textField.layer.backgroundColor = UIColor.white.cgColor
        textField.layer.borderWidth = 1.0
        textField.layer.borderColor = UIColor.black.cgColor
        textField.layer.cornerRadius = 12
        textField.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        textField.textColor = .black
        textField.clearButtonMode = .whileEditing
        textField.addTarget(self, action: #selector (statusTextChanged(_ :)), for: .editingChanged)

        return textField
    }()
    
    private var statusText: String = ""
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func setupViews() {
        [avatarImageView, fullNameLabel, statusLabel, setStatusButton, statusTextField].forEach(){
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            avatarImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            avatarImageView.heightAnchor.constraint(equalToConstant: 120),
            avatarImageView.widthAnchor.constraint(equalToConstant: 120),
            
            fullNameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 27),
            fullNameLabel.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor, constant: 136),
            fullNameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            fullNameLabel.heightAnchor.constraint(equalToConstant: 20),
            fullNameLabel.widthAnchor.constraint(equalToConstant: 220),
            
            statusLabel.topAnchor.constraint(equalTo: topAnchor, constant: 70),
            statusLabel.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor, constant: 136),
            statusLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            statusLabel.heightAnchor.constraint(equalToConstant: 20),
            statusLabel.widthAnchor.constraint(equalToConstant: 220),
        
            
            statusTextField.topAnchor.constraint(equalTo: topAnchor, constant: 100),
            statusTextField.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor, constant: 136),
            statusTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            statusTextField.heightAnchor.constraint(equalToConstant: 40),
            statusTextField.widthAnchor.constraint(equalToConstant: 220),
            
            
            setStatusButton.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 16),
            setStatusButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            setStatusButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            setStatusButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func changeTitleButton() {
           if statusTextField.hasText == true {
               setStatusButton.setTitle("Set status", for: .normal)
           } else {
               setStatusButton.setTitle("Show status", for: .normal)
           }
    }
    
    @objc func buttonTaped(_ sender: UIButton) {
        statusTextChanged(statusTextField)

              if statusText != "" {
                  statusLabel.text = statusText
              } else {
                  print("\(statusLabel.text!)")
              }
    }

    @objc func statusTextChanged(_ statusTextField: UITextField) {
        changeTitleButton()
        self.statusText = statusTextField.text!
    }
}
