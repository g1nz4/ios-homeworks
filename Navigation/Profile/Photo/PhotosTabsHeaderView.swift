import UIKit

/// Хедер с капсульными табами «Фото / Альбомы» для экрана фото.
final class PhotosTabsHeaderView: UICollectionReusableView {

    static let reuseId = "PhotosTabsHeaderView"

    var onTabChanged: ((PhotosViewController.Tab) -> Void)?

    private lazy var tabsControl: CapsuleTabsControl = {
        let control = CapsuleTabsControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        control.titles = ["Фото", "Альбомы"]
        control.onSelectIndex = { [weak self] index in
            guard let self else { return }
            let tab: PhotosViewController.Tab = (index == 0) ? .photos : .albums
            self.onTabChanged?(tab)
        }
        
        return control
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
        tabsControl.setSelectedIndex(0, animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .appBackground
        addSubview(tabsControl)
        
        NSLayoutConstraint.activate([
            tabsControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            tabsControl.widthAnchor.constraint(equalToConstant: 200.0),
            tabsControl.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            tabsControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            tabsControl.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    func configure(selectedTab: PhotosViewController.Tab) {
        let index = (selectedTab == .photos) ? 0 : 1
        tabsControl.setSelectedIndex(index, animated: false)
    }
}
