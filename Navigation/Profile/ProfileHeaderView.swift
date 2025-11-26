import UIKit

class ProfileHeaderView: UIView {

    private lazy var avatarImageView: UIImageView = {
         let imageView = UIImageView()
         imageView.image = UIImage(named: "SimpleCat")
         imageView.frame = CGRect(x: 16, y: 116, width: 100, height: 100)
         imageView.layer.borderWidth = 3
         imageView.layer.borderColor = (UIColor(white: 242.0/255.0, alpha: 1.0)).cgColor
         imageView.contentMode = .scaleAspectFit
         imageView.clipsToBounds = true
         imageView.layer.cornerRadius = 50
         imageView.translatesAutoresizingMaskIntoConstraints = true
         
         return imageView
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Cat Developer"
        label.textColor = .black
        label.frame = CGRect(x: 142, y: 127, width: 220, height: 20)
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = true
        
        return label
    }()
    
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.frame = CGRect(x: 142, y: 160, width: 220, height: 20)
        label.text = "I'm cat ios-developer :)"
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = true
        
        return label
    }()
    
    private lazy var button: UIButton = {
       let button = UIButton()
        button.setTitle("Show Status", for: .normal)
        button.layer.shadowOffset = CGSize(width: 4.0, height: 4.0)
        button.layer.shadowRadius = 4.0
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.7
        button.layer.backgroundColor = UIColor.systemBlue.cgColor
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 4
        button.layer.frame = CGRect(x: 16, y: 232, width: 368, height: 50)
        button.translatesAutoresizingMaskIntoConstraints = true
        button.addTarget(self, action: #selector (buttonTaped(_ :)), for: .touchUpInside)
        
        return button
    }()
    
    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Введите текст..."
        textField.layer.backgroundColor = UIColor.white.cgColor
        textField.layer.borderWidth = 1.0
        textField.layer.borderColor = UIColor.black.cgColor
        textField.layer.cornerRadius = 12
        textField.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        textField.textColor = .black
        textField.frame = CGRect(x: 142, y: 181, width: 220, height: 40)
        textField.clearButtonMode = .whileEditing
        textField.translatesAutoresizingMaskIntoConstraints = true
        textField.addTarget(self, action: #selector (statusTextChanged(_ :)), for: .editingChanged)

        return textField
    }()
    
    private var statusText: String = ""
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        setupViews()
    }
    
    private func setupViews() {
        [avatarImageView, nameLabel, statusLabel, button, textField].forEach(){
            addSubview($0)
        }
    }
    
    private func changeTitleButton() {
           if textField.hasText == true {
               button.setTitle("Set status", for: .normal)
           } else {
               button.setTitle("Show status", for: .normal)
           }
    }
    
    @objc func buttonTaped(_ sender: UIButton) {
        statusTextChanged(textField)

              if statusText != "" {
                  statusLabel.text = statusText
              } else {
                  print("\(statusLabel.text!)")
              }
    }

    @objc func statusTextChanged(_ textField: UITextField) {
        changeTitleButton()
        self.statusText = textField.text!
    }
}
