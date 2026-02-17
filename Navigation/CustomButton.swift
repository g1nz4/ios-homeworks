import UIKit

final class CustomButton: UIButton {
    
    private var tappedOnButton: (() -> Void)?
   
    init(title: String,
         titleColor: UIColor = .white,
         backgroundColor: UIColor = .systemBlue,
         font: UIFont = .systemFont(ofSize: 18.0, weight: .medium),
         cornerRadius: CGFloat = 8.0,
         tappedOnButton: (() -> Void)? = nil
    ) {
        super.init(frame: .zero)
        self.tappedOnButton = tappedOnButton
        self.setTitle(title, for: .normal)
        self.setTitleColor(titleColor, for: .normal)
        self.backgroundColor = backgroundColor
        self.titleLabel?.font = font
        self.layer.cornerRadius = cornerRadius
        self.clipsToBounds = true
        self.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setActionButton(_ action: @escaping () -> Void) {
        self.tappedOnButton = action
    }
    
    @objc private func buttonTapped() {
        tappedOnButton?()
    }
}
