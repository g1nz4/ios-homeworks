import UIKit

/// Фоновый reusable view для секций (общий фон под секцией).
final class SectionBackgroundView: UICollectionReusableView {
    
    static let elementKind = "SectionBackgroundView"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .appBackground
        layer.cornerRadius = 0
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
