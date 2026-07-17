import UIKit

// Режим повтора трека/плейлиста
enum RepeatMode: Int {
    case none
    case one
    case all

    /// Имя SF Symbol для текущего режима
    var iconName: String {
        switch self {
        case .none: 
            return "repeat"
        case .all:  
            return "repeat"
        case .one:  
            return "repeat.1"
        }
    }
}

/// Конфигурация мини‑плеера, прилетает снаружи.
struct MiniPlayerConfig {
    let fullTitle: String
    let isPlaying: Bool
    let isInMyTracks: Bool
    let progress: Float
    let repeatMode: RepeatMode
}

/// Мини‑плеер с бегущей строкой и кнопками управления.
final class MiniPlayerView: UIView {
    /// Нажатие по play/pause.
    var onPlayPause: (() -> Void)?
    /// Нажатие по плюс/галочка (добавить/удалить из избранного).
    var onAddOrRemove: (() -> Void)?
    /// Нажатие по крестику (закрыть мини‑плеер).
    var onClose: (() -> Void)?
    /// Нажатие по кнопке «предыдущий трек».
    var onPrev: (() -> Void)?
    /// Нажатие по кнопке «следующий трек».
    var onNext: (() -> Void)?
    /// Перемотка по прогресс‑бару (0...1).
    var onSeek: ((Double) -> Void)?
    /// Переключение режима повтора.
    var onToggleRepeatMode: (() -> Void)?

    /// Тонкий прогресс‑бар сверху.
    private lazy var progressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .bar)
        view.trackTintColor = .clear
        view.progressTintColor = .appAccent
        
        return view
    }()

    /// Пэн по всей вью для перемотки.
    private lazy var progressPanGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleProgressPan(_:)))
        return gesture
    }()

    /// Тап по всей вью для перемотки.
    private lazy var progressTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleProgressTap(_:)))
        return gesture
    }()

    /// Кнопка "предыдущий трек".
    private lazy var prevButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "backward.fill"), for: .normal)
        button.tintColor = .appAccent
        button.addTarget(self, action: #selector(handlePrev), for: .touchUpInside)
        
        return button
    }()

    /// Кнопка Play/Pause.
    private lazy var playPauseButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "play.fill"), for: .normal)
        button.tintColor = .appAccent
        button.addTarget(self, action: #selector(handlePlayPause), for: .touchUpInside)
        
        return button
    }()

    /// Кнопка "следующий трек"».
    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "forward.fill"), for: .normal)
        button.tintColor = .appAccent
        button.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
        
        return button
    }()

    /// Кнопка плюс/галочка (добавить/удалить из моих треков).
    private lazy var addOrCheckButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .appAccent
        button.addTarget(self, action: #selector(handleAddOrRemove), for: .touchUpInside)
        
        return button
    }()

    /// Кнопка закрытия мини‑плеера.
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .appSecondaryText
        button.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        
        return button
    }()

    /// Кнопка повтора (режим повторения).
    private lazy var repeatButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .appAccent
        button.addTarget(self, action: #selector(handleToggleRepeat), for: .touchUpInside)
        
        return button
    }()

    /// Скролл‑вью, которая отображает только видимую часть текста.
    private lazy var marqueeScrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.isUserInteractionEnabled = false
        scroll.clipsToBounds = true
        
        return scroll
    }()

    /// Контейнер, внутри которого лежат две копии лейбла.
    private lazy var marqueeContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
      
        return view
    }()

    /// Основной лейбл с текстом трека.
    private lazy var marqueeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .appPrimaryText
        
        return label
    }()

    /// Копия лейбла, чтобы создать "живую" прокрутку.
    private lazy var marqueeLabelCopy: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .appPrimaryText
        
        return label
    }()
    
    /// Идет ли сейчас анимация бегущей строки.
    private var marqueeAnimationRunning = false

    /// Расстояние между концом первого и началом второго лейбла.
    private let marqueeSpacing: CGFloat = 40

    /// Последний текст, который показывался (для детекта смены трека).
    private var lastTitle: String?

    /// Ширина видимой области в прошлый layout pass (для оптимизаций).
    private var lastVisibleWidth: CGFloat = 0

    /// Констрейнты ширины лейблов (обновляем после пересчета intrinsicContentSize).
    private var labelWidthConstraint: NSLayoutConstraint?
    private var labelCopyWidthConstraint: NSLayoutConstraint?

    /// Локальное состояние "в избранном ли трек".  Если nil — используется состояние из входного Config.
    private var isInMyTracksState: Bool?


    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureUI()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateMarqueeLayoutIfNeeded()
    }

    /// Базовая настройка самой вью.
    private func configureUI() {
        backgroundColor = UIColor.appSecondaryBackground.withAlphaComponent(0.90)

        [progressView,
         marqueeScrollView,
         repeatButton,
         prevButton,
         playPauseButton,
         nextButton,
         addOrCheckButton,
         closeButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        [marqueeLabel, marqueeLabelCopy].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            marqueeContainer.addSubview($0)
        }

        marqueeScrollView.addSubview(marqueeContainer)
    
        // Высота мини‑плеера
        heightAnchor.constraint(equalToConstant: 70).isActive = true

        // Прогресс‑бар сверху
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: topAnchor),
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2)
        ])

        // Бегущая строка
        NSLayoutConstraint.activate([
            marqueeScrollView.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 4),
            marqueeScrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            marqueeScrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            marqueeScrollView.heightAnchor.constraint(equalToConstant: 18),

            marqueeContainer.topAnchor.constraint(equalTo: marqueeScrollView.topAnchor),
            marqueeContainer.bottomAnchor.constraint(equalTo: marqueeScrollView.bottomAnchor),
            marqueeContainer.leadingAnchor.constraint(equalTo: marqueeScrollView.leadingAnchor),
            marqueeContainer.trailingAnchor.constraint(equalTo: marqueeScrollView.trailingAnchor),
            marqueeContainer.heightAnchor.constraint(equalTo: marqueeScrollView.heightAnchor),

            marqueeLabel.leadingAnchor.constraint(equalTo: marqueeContainer.leadingAnchor),
            marqueeLabel.centerYAnchor.constraint(equalTo: marqueeContainer.centerYAnchor),

            marqueeLabelCopy.leadingAnchor.constraint(equalTo: marqueeLabel.trailingAnchor, constant: marqueeSpacing),
            marqueeLabelCopy.centerYAnchor.constraint(equalTo: marqueeContainer.centerYAnchor),
            marqueeLabelCopy.trailingAnchor.constraint(equalTo: marqueeContainer.trailingAnchor)
        ])

        // Кнопки управления
        NSLayoutConstraint.activate([
            // Повтор слева
            repeatButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            repeatButton.topAnchor.constraint(equalTo: marqueeScrollView.bottomAnchor, constant: 4),
            repeatButton.widthAnchor.constraint(equalToConstant: 26),
            repeatButton.heightAnchor.constraint(equalTo: repeatButton.widthAnchor),

            // Play/Pause по центру
            playPauseButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            playPauseButton.centerYAnchor.constraint(equalTo: repeatButton.centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 26),
            playPauseButton.heightAnchor.constraint(equalTo: playPauseButton.widthAnchor),

            // Prev/Next вокруг Play/Pause
            prevButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            prevButton.trailingAnchor.constraint(equalTo: playPauseButton.leadingAnchor, constant: -12),
            prevButton.widthAnchor.constraint(equalToConstant: 22),
            prevButton.heightAnchor.constraint(equalTo: prevButton.widthAnchor),

            nextButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            nextButton.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 12),
            nextButton.widthAnchor.constraint(equalToConstant: 22),
            nextButton.heightAnchor.constraint(equalTo: nextButton.widthAnchor),

            // Правая часть: плюс/галочка и крестик
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            closeButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),

            addOrCheckButton.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -12),
            addOrCheckButton.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),

            // Низ вью
            playPauseButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])

        // Констрейнты ширины для лейблов (обновим позже по intrinsicContentSize).
        labelWidthConstraint = marqueeLabel.widthAnchor.constraint(equalToConstant: 0)
        labelWidthConstraint?.isActive = true

        labelCopyWidthConstraint = marqueeLabelCopy.widthAnchor.constraint(equalToConstant: 0)
        labelCopyWidthConstraint?.isActive = true
    }

    /// Жесты для работы с прогресс‑баром.
    private func setupGestures() {
        addGestureRecognizer(progressPanGesture)
        addGestureRecognizer(progressTapGesture)
    }

    /// Основной метод конфигурации UI.
    func configure(_ config: MiniPlayerConfig) {
        // Обновить текст только если трек поменялся
        if config.fullTitle != lastTitle {
            lastTitle = config.fullTitle
            marqueeLabel.text = config.fullTitle
            marqueeLabelCopy.text = config.fullTitle
            restartMarqueeForNewText()

            // При смене трека сбросить локальное состояние избранного
            isInMyTracksState = config.isInMyTracks
        }

        // Обновить иконку play/pause
        let playImageName = config.isPlaying ? "pause.fill" : "play.fill"
        playPauseButton.setImage(UIImage(systemName: playImageName), for: .normal)

        let effectiveIsInMyTracks = isInMyTracksState ?? config.isInMyTracks
        updateAddOrCheckIcon(isInMyTracks: effectiveIsInMyTracks)

        // Прогресс ползунка
        progressView.progress = config.progress

        // Обновить кнопку повтора (иконка + цвет)
        repeatButton.setImage(UIImage(systemName: config.repeatMode.iconName), for: .normal)
        switch config.repeatMode {
        case .none:
            repeatButton.tintColor = .appSecondaryText
        case .all, .one:
            repeatButton.tintColor = .appAccent
        }
    }

    /// Отдельный метод, чтобы обновлять только прогресс (без полного конфига).
    func updateProgress(_ progress: Float) {
        progressView.progress = progress
    }

    /// Обновление иконки плюс/галочка.
    private func updateAddOrCheckIcon(isInMyTracks: Bool) {
        let rightImageName = isInMyTracks ? "checkmark" : "plus"
        addOrCheckButton.setImage(UIImage(systemName: rightImageName), for: .normal)
    }

    /// Полный рестарт анимации для нового текста.
    private func restartMarqueeForNewText() {
        marqueeContainer.layer.removeAnimation(forKey: "marqueeTranslation")
        marqueeAnimationRunning = false
        marqueeScrollView.contentOffset = .zero
        updateMarqueeLayoutAndAnimation()
    }

    /// Пересчёт  layout только когда реально изменилась ширина области.
    private func updateMarqueeLayoutIfNeeded() {
        let visibleWidth = marqueeScrollView.bounds.width
        guard abs(visibleWidth - lastVisibleWidth) > 0.5 else { return }
        lastVisibleWidth = visibleWidth
        updateMarqueeLayoutAndAnimation()
    }

    /// Основной метод, который решает: нужна ли анимация, и если да — с какими параметрами.
    private func updateMarqueeLayoutAndAnimation() {
        layoutIfNeeded()

        guard let text = marqueeLabel.text, !text.isEmpty else {
            // Нет текста — нет анимации
            marqueeContainer.layer.removeAnimation(forKey: "marqueeTranslation")
            marqueeAnimationRunning = false
            return
        }

        let labelWidth = marqueeLabel.intrinsicContentSize.width
        let visibleWidth = marqueeScrollView.bounds.width

        // Подогнать ширину лейблов под их intrinsicContentSize
        labelWidthConstraint?.constant = labelWidth
        labelCopyWidthConstraint?.constant = labelWidth

        // Если текст помещается — просто центрировать его, без анимации
        if labelWidth <= visibleWidth {
            marqueeLabelCopy.isHidden = true
            marqueeContainer.layer.removeAnimation(forKey: "marqueeTranslation")
            marqueeAnimationRunning = false
            marqueeScrollView.contentOffset = .zero
            return
        }

        // Текст не помещается — включаем "живую" прокрутку
        marqueeLabelCopy.isHidden = false
        startMarqueeAnimation(labelWidth: labelWidth)
    }

    /// Запускает бесконечную анимацию смещения контейнера.
    private func startMarqueeAnimation(labelWidth: CGFloat) {
        guard !marqueeAnimationRunning else { return }
        marqueeAnimationRunning = true

        let step = labelWidth + marqueeSpacing

        // скорость анимации
        let baseSpeed: CGFloat = 30
        let duration = CFTimeInterval(step / baseSpeed)

        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.byValue = -step
        animation.duration = duration
        animation.repeatCount = .infinity
        animation.isAdditive = true
        animation.timingFunction = CAMediaTimingFunction(name: .linear)

        marqueeContainer.layer.add(animation, forKey: "marqueeTranslation")
    }

    @objc private func handlePlayPause() {
        onPlayPause?()
    }

    @objc private func handleAddOrRemove() {
        // Переключить локальное состояние, чтобы UI не ждал ответа сети
        let current = isInMyTracksState ?? false
        let newValue = !current
        isInMyTracksState = newValue
        updateAddOrCheckIcon(isInMyTracks: newValue)

        onAddOrRemove?()
    }

    @objc private func handleClose() {
        onClose?()
    }

    @objc private func handlePrev() {
        onPrev?()
    }

    @objc private func handleNext() {
        onNext?()
    }

    @objc private func handleToggleRepeat() {
        onToggleRepeatMode?()
    }

    /// Обработка тапа по вью — выставить новый прогресс и сразу отправить seek.
    @objc private func handleProgressTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        let x = max(0, min(location.x, bounds.width))
        let value = bounds.width > 0 ? Double(x / bounds.width) : 0
        progressView.progress = Float(value)
        onSeek?(value)
    }

    /// Обработка пэна — во время жеста крутить прогресс,  по окончании отправить seek.
    @objc private func handleProgressPan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        let x = max(0, min(location.x, bounds.width))
        let value = bounds.width > 0 ? Double(x / bounds.width) : 0

        switch gesture.state {
        case .began, .changed:
            progressView.progress = Float(value)
        case .ended, .cancelled, .failed:
            onSeek?(value)
        default:
            break
        }
    }
}
