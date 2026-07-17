import UIKit

/// Базовый нижний лист с затемнением, жестом свайпа вниз и анимацией появления/скрытия.
/// Наследники переопределяют `configureContent()` и наполняют `contentStackView` своими вью.
class BottomSheetViewController: UIViewController {
    
    /// Стек, в который наследники добавляют свой контент.
    /// Используем UIStackView, чтобы удобно раскладывать элементы по вертикали.
    let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }()
    
    /// Полупрозрачный тёмный фон за шторкой.
    /// Накрывает весь экран, принимает тап для закрытия шторки.
    private lazy var dimmingView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        view.alpha = 0 // изначально скрыт, появится при анимации
        
        // Тап по затемнению закрывает шторку
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapClose))
        view.addGestureRecognizer(tap)
        
        return view
    }()
    
    /// Основной контейнер нижнего листа (sheet).
    /// Здесь висит жест панорамирования вниз для интерактивного закрытия.
    private lazy var sheetView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .appBackground
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.masksToBounds = true
        
        // Жест вниз для закрытия шторки
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)
        
        return view
    }()
    
    /// Внутренний контейнер контента шторки (для отступов от краёв).
    /// Внутрь него кладётся `contentStackView`.
    private lazy var contentContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    
    /// Нижний констрейнт шторки
    private var sheetBottomConstraint: NSLayoutConstraint!
    
    /// Флаг, чтобы анимация появления запускалась только один раз за жизненный цикл контроллера.
    private var didAnimatePresent = false
    
    /// Заполненная высота шторки в уже разложенном состоянии.
    private var sheetHeight: CGFloat = 0
    
    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Фон основного view прозрачный: сам фон рисует dimmingView
        view.backgroundColor = .clear
        
        setupHierarchy()
        setupConstraints()
        
        // Наследники наполняют стек своим контентом
        configureContent()
        
        // Обеспечить первичный лейаут
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        prepareInitialTransformIfNeeded()
        animatePresentIfNeeded()
    }
    
    /// Наследники переопределяют этот метод и наполняют `contentStackView`.
    func configureContent() { }
    
    /// Публичный метод для закрытия листа.
    func dismissSheet(animated: Bool = true, completion: (() -> Void)? = nil) {
        if animated {
            animateDismiss(completion: completion)
        } else {
            dismiss(animated: false, completion: completion)
        }
    }
    
    /// Добавляет все сабвью и выстраивает иерархию.
    private func setupHierarchy() {
        view.addSubview(dimmingView)
        view.addSubview(sheetView)
        
        sheetView.addSubview(contentContainerView)
        contentContainerView.addSubview(contentStackView)
    }
    
    ///Auto Layout констрейнты для всех элементов.
    private func setupConstraints() {
        sheetBottomConstraint = sheetView.bottomAnchor.constraint(
            equalTo: view.bottomAnchor,
            constant: 0
        )
        
        NSLayoutConstraint.activate([
            // Dimming — на весь экран (фон под шторкой)
            dimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Sheet: по ширине на весь экран, прижат к низу через bottom-констрейнт
            sheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheetBottomConstraint,
            
            // Минимальная высота листа — 45% экрана.
            sheetView.heightAnchor.constraint(greaterThanOrEqualTo: view.heightAnchor, multiplier: 0.45),
            
            // Контейнер контента с внутренними отступами и учётом safe area.
            contentContainerView.topAnchor.constraint(
                equalTo: sheetView.safeAreaLayoutGuide.topAnchor,
                constant: 16
            ),
            contentContainerView.leadingAnchor.constraint(
                equalTo: sheetView.leadingAnchor,
                constant: 16
            ),
            contentContainerView.trailingAnchor.constraint(
                equalTo: sheetView.trailingAnchor,
                constant: -16
            ),
            contentContainerView.bottomAnchor.constraint(
                lessThanOrEqualTo: sheetView.safeAreaLayoutGuide.bottomAnchor,
                constant: -16
            ),
            
            // Стек внутри контейнера без дополнительных отступов.
            contentStackView.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentContainerView.bottomAnchor)
        ])
    }
    
    /// Подготавливает стартовое положение листа (полностью под экраном) и запоминает его высоту.
    /// Вызывается в `viewDidAppear`, когда весь лейаут уже стабилен.
    private func prepareInitialTransformIfNeeded() {
        // Если высота уже посчитана, повторно ничего не делать
        guard sheetHeight == 0 else { return }
        
        // Финальный лейаут на всякий случай
        view.layoutIfNeeded()
        
        // Замер высоты шторки в её финальном состоянии
        sheetHeight = sheetView.bounds.height
        
        // Стартовое положение — полностью под экраном (сдвиг вниз на собственную высоту)
        sheetView.transform = CGAffineTransform(translationX: 0, y: sheetHeight)
        
        // Затемнение пока скрыто: появится синхронно с анимацией листа
        dimmingView.alpha = 0
    }
    
    /// Запускает анимацию появления, если она ещё не была запущена.
    private func animatePresentIfNeeded() {
        guard !didAnimatePresent else { return }
        didAnimatePresent = true
        animatePresent()
    }
    
    /// Анимация появления листа снизу и одновременное проявление затемнения.
    private func animatePresent() {
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0.6,
            options: [.curveEaseOut]
        ) {
            // Лист поднимается в своё финальное положение
            self.sheetView.transform = .identity
            
            // Затемнение плавно проявляется до полной видимости
            self.dimmingView.alpha = 1
        }
    }
    
    /// Анимация скрытия листа и затемнения.
    private func animateDismiss(completion: (() -> Void)? = nil) {
        UIView.animate(
            withDuration: 0.3,
            animations: {
                // Затемнение исчезает
                self.dimmingView.alpha = 0
                
                // Лист уезжает вниз под экран на свою высоту
                self.sheetView.transform = CGAffineTransform(translationX: 0, y: self.sheetHeight)
            },
            completion: { [weak self] _ in
                // После окончания анимации закрыть контроллер без дополнительной системной анимации
                self?.dismiss(animated: false, completion: completion)
            }
        )
    }
    
    /// Тап по затемнению — закрытие листа с анимацией.
    @objc private func didTapClose() {
        animateDismiss()
    }
    
    /// Обработка пан-жеста по листу (свайп вниз для интерактивного закрытия).
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        
        switch gesture.state {
        case .changed:
            // только движение вниз, при движении вверх игнорировать жест
            guard translation.y > 0 else { return }
            
            // Сдвинуть лист вниз на величину жеста
            sheetView.transform = CGAffineTransform(translationX: 0, y: translation.y)
            
            // Прогресс закрытия от 0 до 1, где 1 — лист полностью ушёл вниз
            let progress = min(1, sheetHeight == 0 ? 0 : translation.y / sheetHeight)
            
            // Чем больше прогресс, тем более прозрачным становится затемнение
            dimmingView.alpha = 1 - progress
            
        case .ended, .cancelled:
            // Закрывать лист если пользователь протащил больше 30% высоты
            let shouldDismiss: Bool
            if sheetHeight > 0 {
                shouldDismiss = translation.y > sheetHeight * 0.3
            } else {
                shouldDismiss = translation.y > 60
            }
            
            if shouldDismiss {
                // Плавно дотянуть лист до полного закрытия
                animateDismiss()
            } else {
                // Вернуть лист и затемнение в исходное положение
                UIView.animate(withDuration: 0.2) {
                    self.sheetView.transform = .identity
                    self.dimmingView.alpha = 1
                }
            }
            
        default:
            break
        }
    }
}
