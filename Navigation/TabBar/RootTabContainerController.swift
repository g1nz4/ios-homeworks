import UIKit

protocol RootTabContainerControllerDelegate: AnyObject {
    /// Вызывается при повторном тапе по уже выбранной вкладке.
    func tabWasReselected(index: Int)
}

/// Модель одного таба.
struct TabItem {
    let title: String
    let systemImageName: String
}

/// Контейнер, реализующий корневую навигацию с помощью: кастомного таббара снизу (`CustomTabBarView`) и `UIPageViewController` для свайпов между вкладками.
final class RootTabContainerController: UIViewController {
    
    weak var delegate: RootTabContainerControllerDelegate?
    
    /// Текущий индекс выбранной вкладки.
    var selectedIndex: Int = 0 {
        didSet {
            guard selectedIndex >= 0,
                  selectedIndex < controllers.count
            else { return }
            switchTo(index: selectedIndex, animated: true)
        }
    }
    
    /// Контроллеры для каждой вкладки.
    private let controllers: [UIViewController]
    
    /// Элементы табов (соответствуют `controllers` по индексу).
    private let items: [TabItem]
    
    /// Контейнер для содержимого (внутри него — pageViewController.view).
    private lazy var contentContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .appBackground
        
        return view
    }()
    
    /// Кастомный таббар с иконками.
    private lazy var tabBarView: CustomTabBarView = {
        let view = CustomTabBarView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    /// `pageViewController` для перелистывания вкладок свайпом.
    private let pageViewController: UIPageViewController = {
        let pageVC = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        return pageVC
    }()
    
    /// Констрейнт: низ контента привязан к верхнему краю таббара.
    private var contentBottomToTabBar: NSLayoutConstraint!
    /// Констрейнт: низ контента привязан к низу экрана (когда таббар скрыт).
    private var contentBottomToView: NSLayoutConstraint!
    
    init(controllers: [UIViewController], items: [TabItem]) {
        self.controllers = controllers
        self.items = items
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupPageViewController()
        setupCallbacks()
        tabBarView.configure(with: items)
        selectedIndex = 2
        setInitialPage(index: selectedIndex)
    }
    
    private func setupUI() {
        view.backgroundColor = .appBackground
        
        [contentContainer, tabBarView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    
        addChild(pageViewController)
        contentContainer.addSubview(pageViewController.view)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])
        pageViewController.didMove(toParent: self)

        contentBottomToTabBar = contentContainer.bottomAnchor.constraint(equalTo: tabBarView.topAnchor)
        contentBottomToView = contentContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        // по умолчанию контент над таббаром
        contentBottomToView.isActive = false

        NSLayoutConstraint.activate([
            tabBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tabBarView.heightAnchor.constraint(equalToConstant: 40),

            contentContainer.topAnchor.constraint(equalTo: view.topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentBottomToTabBar
        ])
    }
    
    /// Настройка dataSource/ delegate у `UIPageViewController`.
    private func setupPageViewController() {
        pageViewController.dataSource = self
        pageViewController.delegate = self
    }
    
    /// Устанавливает начальный контроллер для pageVC.
    private func setInitialPage(index: Int) {
        guard index >= 0, index < controllers.count else { return }
        let vc = controllers[index]
        pageViewController.setViewControllers([vc], direction: .forward, animated: false)
        tabBarView.setSelected(index: index)
    }
    
    /// Подписки на события таббара.
    private func setupCallbacks() {
        tabBarView.onSelectIndex = { [weak self] index in
            guard let self else { return }

            if index == self.selectedIndex {
                // тап по уже выбранному табу
                self.delegate?.tabWasReselected(index: index)
            } else {
                self.selectedIndex = index
            }
        }
    }
    
    /// Показать/скрыть таббар, при необходимости — с анимацией.
    func setTabBarHidden(_ hidden: Bool, animated: Bool) {
        view.layoutIfNeeded()
        
        contentBottomToTabBar.isActive = !hidden
        contentBottomToView.isActive = hidden
        
        let changes = {
            self.tabBarView.alpha = hidden ? 0.0 : 1.0
            self.tabBarView.isUserInteractionEnabled = !hidden
            self.view.layoutIfNeeded()
        }
        
        if animated {
            UIView.animate(withDuration: 0.25, animations: changes)
        } else {
            changes()
        }
    }
    
    /// Переключиться на контроллер по индексу.
    private func switchTo(index: Int, animated: Bool) {
        guard index >= 0, index < controllers.count else { return }
        
        let newVC = controllers[index]
        guard let currentVC = pageViewController.viewControllers?.first else {
            pageViewController.setViewControllers([newVC], direction: .forward, animated: false)
            tabBarView.setSelected(index: index)
            return
        }
        
        let currentIndex = controllers.firstIndex(of: currentVC) ?? 0
        let direction: UIPageViewController.NavigationDirection =
            index >= currentIndex ? .forward : .reverse
        
        pageViewController.setViewControllers(
            [newVC],
            direction: direction,
            animated: animated
        )
        
        tabBarView.setSelected(index: index)
    }
}

// MARK: - UIPageViewControllerDataSource & Delegate

extension RootTabContainerController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let index = controllers.firstIndex(of: viewController),
              index > 0 else { return nil }
        return controllers[index - 1]
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let index = controllers.firstIndex(of: viewController),
              index < controllers.count - 1 else { return nil }
        return controllers[index + 1]
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed,
              let currentVC = pageViewController.viewControllers?.first,
              let index = controllers.firstIndex(of: currentVC) else { return }
        
        // обновить состояние при свайпе
        selectedIndex = index
        tabBarView.setSelected(index: index)
    }
}

// MARK: - Helper: доступ к RootTabContainerController из дочерних контроллеров

extension UIViewController {
    /// Возвращает ближайший RootTabContainerController в иерархии.
    var rootTabContainerController: RootTabContainerController? {
        var parentVC = parent
        while let current = parentVC {
            if let root = current as? RootTabContainerController {
                return root
            }
            parentVC = current.parent
        }
        return nil
    }
}
