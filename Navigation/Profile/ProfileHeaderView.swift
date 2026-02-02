import UIKit

class ProfileHeaderView: UIView {
    
    private lazy var contentView: UIView = {
        let view = UIView()
        
        return view
    }()
    
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0.0
       
        return view
    }()
    
    private lazy var closeSymbol: UIImageView = {
        let symbol = UIImageView()
        symbol.image = UIImage(systemName: "xmark.circle")
        symbol.tintColor = .black
        symbol.alpha = 0.0
        symbol.isUserInteractionEnabled = true
        let tapSymbol = UITapGestureRecognizer(
            target: self,
            action: #selector(didTapOnCloseSymbol))
        symbol.addGestureRecognizer(tapSymbol)
        
        return symbol
    }()
    
    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "SimpleCat")
        imageView.layer.borderWidth = 3.0
        imageView.layer.borderColor = (UIColor(white: 242.0/255.0, alpha: 1.0)).cgColor
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 60.0
        imageView.alpha = 1.0
        imageView.isUserInteractionEnabled = true
        imageView.layer.isOpaque = true
        let tapImage = UITapGestureRecognizer(
            target: self,
            action: #selector(didTapOnAvatar)
        )
        tapImage.numberOfTapsRequired = 1
        imageView.addGestureRecognizer(tapImage)
        
        
        return imageView
    }()
    
    private lazy var fullNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Cat Developer"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 18.0, weight: .bold)
        label.textColor = .black
        
        return label
    }()
    
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.text = "I'm cat ios-developer :)"
        label.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
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
        button.layer.cornerRadius = 4.0
        button.addTarget(
            self,
            action: #selector (buttonTaped(_ :)),
            for: .touchUpInside)
        
        return button
    }()
    
    private lazy var statusTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = " Введите..."
        textField.layer.backgroundColor = UIColor.white.cgColor
        textField.layer.borderWidth = 1.0
        textField.layer.borderColor = UIColor.black.cgColor
        textField.layer.cornerRadius = 12.0
        textField.font = UIFont.systemFont(ofSize: 15.0, weight: .regular)
        textField.textColor = .black
        textField.clearButtonMode = .whileEditing
        textField.addTarget(
            self,
            action: #selector (statusTextChanged(_ :)),
            for: .editingChanged
        )
        
        return textField
    }()
    
    private var statusText: String = ""
    
    override init(frame: CGRect) {
        super.init(frame: frame)
       
        addSubviews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func addSubviews() {
        [contentView, fullNameLabel, statusLabel, setStatusButton, statusTextField, avatarImageView, backgroundView, closeSymbol].forEach() {
            $0.translatesAutoresizingMaskIntoConstraints = false
           addSubview($0)
        }
    }
    
    private func setupConstraints() {
        let safeAreaGuide = self.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate(
            [
                contentView.leadingAnchor.constraint(
                    equalTo: safeAreaGuide.leadingAnchor
                ),
                contentView.trailingAnchor.constraint(
                    equalTo: safeAreaGuide.trailingAnchor
                ),
                contentView.topAnchor.constraint(
                    equalTo: safeAreaGuide.topAnchor
                ),
                contentView.bottomAnchor.constraint(
                    equalTo: safeAreaGuide.bottomAnchor
                ),
                avatarImageView.topAnchor.constraint(
                    equalTo:  contentView.topAnchor,
                    constant: 16.0
                ),
                avatarImageView.leadingAnchor.constraint(
                    equalTo:  contentView.leadingAnchor,
                    constant: 16.0
                ),
                avatarImageView.heightAnchor.constraint(
                    equalToConstant: 120.0
                ),
                avatarImageView.widthAnchor.constraint(
                    equalToConstant: 120.0
                ),
                fullNameLabel.topAnchor.constraint(
                    equalTo: contentView.topAnchor,
                    constant: 27.0
                ),
                fullNameLabel.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor,
                    constant: 152.0
                ),
                fullNameLabel.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor,
                    constant: -16.0
                ),
                fullNameLabel.heightAnchor.constraint(
                    equalToConstant: 20.0
                ),
                fullNameLabel.widthAnchor.constraint(
                    equalToConstant: 220.0
                ),
                statusLabel.topAnchor.constraint(
                    equalTo: contentView.topAnchor,
                    constant: 70.0
                ),
                statusLabel.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor,
                    constant: 152.0
                ),
                statusLabel.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor,
                    constant: -16.0
                ),
                statusLabel.heightAnchor.constraint(
                    equalToConstant: 20.0
                ),
                statusLabel.widthAnchor.constraint(
                    equalToConstant: 220.0
                ),
                statusTextField.topAnchor.constraint(
                    equalTo: contentView.topAnchor,
                    constant: 100.0
                ),
                statusTextField.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor,
                    constant: 152.0
                ),
                statusTextField.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor,
                    constant: -16.0
                ),
                statusTextField.heightAnchor.constraint(
                    equalToConstant: 40.0
                ),
                statusTextField.widthAnchor.constraint(
                    equalToConstant: 220.0
                ),
                setStatusButton.topAnchor.constraint(
                    equalTo: contentView.topAnchor,
                    constant: 152.0
                ),
                setStatusButton.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor,
                    constant: 16.0
                ),
                setStatusButton.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor,
                    constant: -16.0
                ),
                setStatusButton.heightAnchor.constraint(
                    equalToConstant: 50.0
                ),
                setStatusButton.bottomAnchor.constraint(
                    equalTo: contentView.bottomAnchor,
                    constant: -16.0
                ),
                backgroundView.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor
                ),
                backgroundView.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor
                ),
                backgroundView.topAnchor.constraint(
                    equalTo: contentView.topAnchor
                ),
                backgroundView.heightAnchor.constraint(
                    equalToConstant: 800.0
                ),
                closeSymbol.topAnchor.constraint(
                    equalTo: backgroundView.topAnchor,
                    constant: 16.0
                ),
                closeSymbol.trailingAnchor.constraint(
                    equalTo: backgroundView.trailingAnchor,
                    constant: -16.0
                ),
                closeSymbol.widthAnchor.constraint(
                    equalToConstant: 50.0
                ),
                closeSymbol.heightAnchor.constraint(
                    equalToConstant: 50.0
                )
            ]
        )
    }
    
    private func launchAnimation() {
        let centerOrigin = avatarImageView.center

        UIView.animate(
            withDuration: 0.5,
            delay: 0.1,
            options: .curveLinear
        ) {
            self.avatarImageView.layer.borderWidth = 0.0
            self.avatarImageView.layer.cornerRadius = 0.0
           
            self.layer.insertSublayer(
                self.backgroundView.layer,
                below: self.avatarImageView.layer
            )
            self.backgroundView.alpha = 0.7
            
            self.avatarImageView.center = CGPoint(
                x: centerOrigin.x * 2.65,
                y: centerOrigin.y * 4.75
            )
            self.avatarImageView.transform = CGAffineTransform(
                scaleX: 3.4,
                y: 3.4
            )
            
            UIView.animate(
                withDuration: 0.3,
                delay: 0.0,
                options: .curveLinear
            ) {
                self.closeSymbol.alpha = 1.0
            }
        }
    }
    
    private func reverseAnimation() {
        let centerOrigin = avatarImageView.center
       
        UIView.animate(
            withDuration: 0.3,
            delay: 0.0,
            options: .curveLinear
        ) {
            self.closeSymbol.alpha = 0.0
        }
        
        UIView.animate(
            withDuration: 0.5,
            delay: 0.0,
            options: .curveLinear
        ) {
            self.avatarImageView.transform = CGAffineTransform(
                translationX: -3.4,
                y: -3.4
            )
            self.avatarImageView.center = CGPoint(
                x: centerOrigin.x / 2.65,
                y: centerOrigin.y / 4.75
            )
            self.avatarImageView.layer.borderWidth = 3.0
            self.avatarImageView.layer.cornerRadius = 60
            self.backgroundView.alpha = 0.0
        }
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
    
    @objc func didTapOnAvatar() {
        launchAnimation()
    }
    
    @objc func didTapOnCloseSymbol() {
        reverseAnimation()
    }
}
    
    
