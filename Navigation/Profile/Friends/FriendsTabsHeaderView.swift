import UIKit

/// Хедер с капсульными табами Друзья / Online для экрана друзей.
final class FriendsTabsHeaderView: UICollectionReusableView {

    static let reuseId = "FriendsTabsHeaderView"

    /// Колбэк при смене таба.
    var onTabChanged: ((Int) -> Void)?
    
    private lazy var tabsControl: CapsuleTabsControl = {
        let control = CapsuleTabsControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        control.titles = ["Друзья", "Online"]
        control.onSelectIndex = { [weak self] index in
            self?.onTabChanged?(index)
        }
        return control
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        addSubview(tabsControl)

        NSLayoutConstraint.activate([
            tabsControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            tabsControl.widthAnchor.constraint(equalToConstant: 200.0),
            tabsControl.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            tabsControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            tabsControl.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        tabsControl.setSelectedIndex(0, animated: false)
    }

    /// Вызывается из контроллера, когда известно кол-во друзей.
    func configure(allCount: Int, onlineCount: Int, selectedIndex: Int) {
        tabsControl.titles = ["Друзья \(allCount)", "Online \(onlineCount)"]
        tabsControl.setSelectedIndex(selectedIndex, animated: false)
    }
}
