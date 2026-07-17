import UIKit

/// Хедер с табами для экрана музыки.
final class MusicTabsHeaderView: UICollectionReusableView {

    static let reuseId = "MusicTabsHeaderView"

    /// Коллбэк при смене вкладки.
    var onTabChanged: ((MusicTab) -> Void)?

    /// Внутренний порядок вкладок.
    private let tabs: [MusicTab] = [.main, .myTracks]

    private lazy var tabsControl: CapsuleTabsControl = {
        let control = CapsuleTabsControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        control.titles = ["Главная", "Мои треки"]
        control.onSelectIndex = { [weak self] index in
            guard
                let self,
                index >= 0,
                index < self.tabs.count
            else { return }

            let tab = self.tabs[index]
            self.onTabChanged?(tab)
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
            tabsControl.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            tabsControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            tabsControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            tabsControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            tabsControl.heightAnchor.constraint(equalToConstant: 32)
        ])

        tabsControl.setSelectedIndex(0, animated: false)
    }

    func configure(selectedTab: MusicTab) {
        // найти индекс выбранного таба в массиве tabs
        if let index = tabs.firstIndex(of: selectedTab) {
            tabsControl.setSelectedIndex(index, animated: false)
        }
    }
}
