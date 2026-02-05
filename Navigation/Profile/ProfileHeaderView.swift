import UIKit
import SnapKit

final class ProfileHeaderView: UIView {
    
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
        [
            contentView,
            fullNameLabel,
            statusLabel,
            setStatusButton,
            statusTextField,
            avatarImageView,
            backgroundView,
            closeSymbol
        ].forEach() { addSubview($0) }
    }
    
    private func setupConstraints() {
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(self.safeAreaLayoutGuide)
        }
        
        avatarImageView.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.top).offset(16.0)
            make.leading.equalTo(contentView.snp.leading).offset(16.0)
            make.size.equalTo(CGSize(width: 120.0, height: 120.0))
        }
        
        fullNameLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.top).offset(27.0)
            make.leading.equalTo(contentView.snp.leading).offset(152.0)
            make.trailing.equalTo(contentView.snp.trailing).inset(16.0)
            make.height.equalTo(20.0)
            make.width.equalTo(220.0)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.top).offset(70.0)
            make.leading.equalTo(contentView.snp.leading).offset(152.0)
            make.trailing.equalTo(contentView.snp.trailing).inset(16.0)
            make.height.equalTo(20.0)
            make.width.equalTo(220.0)
        }

        statusTextField.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.top).offset(100.0)
            make.leading.equalTo(contentView.snp.leading).offset(152.0)
            make.trailing.equalTo(contentView.snp.trailing).inset(16.0)
            make.height.equalTo(40.0)
            make.width.equalTo(220.0)
        }
        
        setStatusButton.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.top).offset(152.0)
            make.leading.equalTo(contentView.snp.leading).offset(16.0)
            make.trailing.equalTo(contentView.snp.trailing).inset(16.0)
            make.bottom.equalTo(contentView.snp.bottom).inset(16.0)
            make.height.equalTo(50.0)
        }

        backgroundView.snp.makeConstraints { make in
            make.leading.trailing.top.equalTo(contentView)
            make.height.equalTo(800.0)
           
        }
        
        closeSymbol.snp.makeConstraints { make in
            make.top.equalTo(backgroundView.snp.top).offset(16.0)
            make.trailing.equalTo(backgroundView.snp.trailing).inset(16.0)
            make.size.equalTo(CGSize(width: 50.0, height: 50.0))
        }
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
    
    
