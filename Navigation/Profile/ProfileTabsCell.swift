import UIKit

/// Ячейка с табами профиля (Главная / Посты / Фото / Музыка).
final class ProfileTabsCell: UICollectionViewCell {

    static let reuseId = "ProfileTabsCell"

    /// Колбэк при выборе таба.
    var onSelectTab: ((ProfileTab) -> Void)?

    private lazy var tabsControl: CapsuleTabsControl = {
        let control = CapsuleTabsControl()
        control.titles = ["Главная", "Посты", "Фото", "Музыка"]
        control.onSelectIndex = { [weak self] index in
            guard
                let self,
                let tab = self.tab(for: index)
            else { return }
            self.onSelectTab?(tab)
        }
        
        return control
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureUI()
        // начально выбранный таб — "Главная"
        tabsControl.setSelectedIndex(0, animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        contentView.backgroundColor = .appBackground
        contentView.layer.cornerRadius = 22
        contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentView.layer.masksToBounds = false
   
        contentView.addSubview(tabsControl)
        tabsControl.translatesAutoresizingMaskIntoConstraints = false
   
        NSLayoutConstraint.activate([
            tabsControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            tabsControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            tabsControl.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            tabsControl.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            tabsControl.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    func configure(selectedTab: ProfileTab) {
        tabsControl.setSelectedIndex(index(for: selectedTab), animated: false)
    }


    private func index(for tab: ProfileTab) -> Int {
        switch tab {
        case .main:  return 0
        case .posts: return 1
        case .photos: return 2
        case .music: return 3
        }
    }

    private func tab(for index: Int) -> ProfileTab? {
        switch index {
        case 0: return .main
        case 1: return .posts
        case 2: return .photos
        case 3: return .music
        default: return nil
        }
    }
}
