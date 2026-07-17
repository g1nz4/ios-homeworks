import UIKit
import PhotosUI

/// Делегат StoryViewController для сценария создания истории.
protocol StoryViewControllerDelegate: AnyObject {
    /// Пользователь успешно опубликовал историю.
    func storyCreationDidPublish(_ controller: StoryViewController, items: [UIImage])

    /// Пользователь отменил создание истории (по крестику или свайпу вниз).
    func storyCreationDidCancel(_ controller: StoryViewController)
}

enum StoryMode {
    case create
    case viewOnly
}

/// Универсальный контроллер историй: в режиме `.create` работает с `StoryCreationViewModel`; в режиме `.viewOnly` работает с `StoryPlayerViewModel`.
@MainActor
final class StoryViewController: UIViewController {

    weak var delegate: StoryViewControllerDelegate?

    /// Имя пользователя для шапки в режиме просмотра.
    private let userName: String?

    /// URL строки аватара для шапки в режиме просмотра.
    private let avatarURLString: String?

    /// Текущий режим (создание или просмотр).
    private let mode: StoryMode

    /// VM для просмотра историй (прослушивает из сториджа, крутит таймер).
    private let playerViewModel: StoryPlayerViewModel?

    /// VM для создания истории (подбор картинок, публикация).
    private let creationViewModel: StoryCreationViewModel?

    /// Кеш последнего состояния, которое пришло от VM.
    private var currentState: StoryState?

    /// Верхняя плашка со статус баром истории, аватаром/именем/датой или кнопкой публикации.
    private lazy var topBar: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        
        return view
    }()

    /// Аватар пользователя в режиме просмотра.
    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 14

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 28),
            imageView.heightAnchor.constraint(equalToConstant: 28)
        ])
        return imageView
    }()

    /// Имя пользователя в верхней панели.
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 14)
        label.textColor = .white
        
        return label
    }()

    /// Лейбл с временем создания истории вида "N сек./мин.  назад".
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        return label
    }()

    /// Стек с аватаром, именем и временем.
    private lazy var userInfoStack: UIStackView = {
        let vStack = UIStackView(arrangedSubviews: [nameLabel, dateLabel])
        vStack.axis = .vertical
        vStack.spacing = 2

        let hStack = UIStackView(arrangedSubviews: [avatarImageView, vStack])
        hStack.translatesAutoresizingMaskIntoConstraints = false
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 8
        
        return hStack
    }()

    /// Кнопка закрытия (крестик) - присутствует в обоих режимах.
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        
        return button
    }()

    /// Кнопка "Опубликовать" - только для режима создания.
    private lazy var publishButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Опубликовать", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)

        // начальное состояние: видно, выключено, белый текст
        button.isHidden = false
        button.isEnabled = false
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.white.withAlphaComponent(0.6), for: .disabled)

        button.addTarget(self, action: #selector(didTapPublish), for: .touchUpInside)
        
        return button
    }()

    /// Хедер‑индикатор прогресса сториз (горизонтальный стек из UIProgressView).
    private lazy var progressStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 4
        stack.distribution = .fillEqually
        
        return stack
    }()

    // MARK: - UI: Content & Bottom bar

    /// Основное изображение истории (текущий слайд).
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        
        return imageView
    }()

    /// Нижняя панель в режиме создания (кнопки добавить/удалить).
    private lazy var bottomBar: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        
        return view
    }()

    /// Кнопка "Добавить" (галерея/камера) в режиме создания.
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        button.tintColor = .white
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)
        
        return button
    }()

    /// Кнопка "Удалить текущий слайд" в режиме создания.
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "trash"), for: .normal)
        button.tintColor = .white
        button.contentHorizontalAlignment = .trailing
        button.addTarget(self, action: #selector(didTapDeleteCurrent), for: .touchUpInside)
        
        return button
    }()

    /// Массив прогресс‑баров по количеству слайдов.
    private var progressViews: [UIProgressView] = []

    /// Инициализатор для просмотра сохранённых историй (режим `.viewOnly`).
    /// Parameters: `playerViewModel`VM, читающая истории из storage и управляющая таймером; `mode` режим, по умолчанию `.viewOnly`; ` userName` имя пользователя для шапки; ` avatarURLString` строка URL аватарки.
    init(
        playerViewModel: StoryPlayerViewModel,
        mode: StoryMode = .viewOnly,
        userName: String?,
        avatarURLString: String?
    ) {
        self.mode = mode
        self.playerViewModel = playerViewModel
        self.creationViewModel = nil
        self.userName = userName
        self.avatarURLString = avatarURLString
        super.init(nibName: nil, bundle: nil)
    }

    /// Инициализатор для создания новой истории (режим `.create`).
    /// Parameter: ` creationViewModel` VM для создания истории.
    init(creationViewModel: StoryCreationViewModel) {
        self.mode = .create
        self.playerViewModel = nil
        self.creationViewModel = creationViewModel
        self.userName = nil
        self.avatarURLString = nil
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupHierarchy()
        setupLayout()
        setupGestures()
        bindViewModels()
        callViewModelViewDidLoad()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // При уходе с экрана остановить все таймеры
        playerViewModel?.stopTimer()
        creationViewModel?.stopTimer()
    }

    /// Создает иерархию сабвью: верхняя панель (topBar + стеки/кнопки), нижняя панель (bottomBar при создании).
    private func setupHierarchy() {
        view.addSubview(imageView)
        view.addSubview(topBar)

        // Контейнер для всего контента в topBar: прогресс + нижняя строка
        let topContent = UIStackView()
        topContent.translatesAutoresizingMaskIntoConstraints = false
        topContent.axis = .vertical
        topContent.spacing = 8

        // Нижняя строка topBar: либо [X ... Опубликовать], либо [avatar+name ... X]
        let bottomTopBar = UIStackView()
        bottomTopBar.axis = .horizontal
        bottomTopBar.alignment = .center
        bottomTopBar.distribution = .fill
        bottomTopBar.spacing = 8
        bottomTopBar.translatesAutoresizingMaskIntoConstraints = false

        topBar.addSubview(topContent)
        topContent.addArrangedSubview(progressStackView)
        topContent.addArrangedSubview(bottomTopBar)

        switch mode {
        case .create:
            // В режиме создания: top: прогресс, bottom: [ X ]  ---spacer---  [ Опубликовать ]
            bottomTopBar.addArrangedSubview(closeButton)

            let spacer = UIView()
            spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
            bottomTopBar.addArrangedSubview(spacer)

            bottomTopBar.addArrangedSubview(publishButton)

            // Нижняя панель с кнопками + / trash
            view.addSubview(bottomBar)
            bottomBar.addSubview(addButton)
            bottomBar.addSubview(deleteButton)

        case .viewOnly:
            // В режиме просмотра: top -> прогресс, под ним -> [ avatar+name ]  ---spacer---  [ X ]
            bottomTopBar.addArrangedSubview(userInfoStack)

            let spacer = UIView()
            spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
            bottomTopBar.addArrangedSubview(spacer)

            bottomTopBar.addArrangedSubview(closeButton)

            // Кнопка публикации скрыта
            publishButton.isHidden = true
        }
    }

    /// Настройка констрейнтов для: ` imageView` на весь экран;  `topBar` под safeArea; `динамический контент` в topBar;  `bottomBar` снизу (в режиме `.create`).
    private func setupLayout() {
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

           
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])

        if let topContent = topBar.subviews.first(where: { $0 is UIStackView }) {
            NSLayoutConstraint.activate([
                topContent.topAnchor.constraint(equalTo: topBar.topAnchor, constant: 8),
                topContent.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 12),
                topContent.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -12),
                topContent.bottomAnchor.constraint(equalTo: topBar.bottomAnchor, constant: -8),

                progressStackView.heightAnchor.constraint(equalToConstant: 4)
            ])
        }
        // Bottom bar присутствует только в режиме создания
        if mode == .create {
            NSLayoutConstraint.activate([
                bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                bottomBar.heightAnchor.constraint(equalToConstant: 70),

                addButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 20),
                addButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),

                deleteButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -20),
                deleteButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor)
            ])
        }
    }

    /// Настройка жестов:  tap  для навигации по слайдам; свайп вниз для закрытия.
    private func setupGestures() {
        let tapRight = UITapGestureRecognizer(target: self, action: #selector(didTapRight(_:)))
        view.addGestureRecognizer(tapRight)

        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeDown(_:)))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
    }

    private func bindViewModels() {
        if let creationVM = creationViewModel {
            // ===== РЕЖИМ СОЗДАНИЯ =====
            creationVM.onStateChange = { [weak self] state in
                guard let self else { return }
                self.currentState = state
                self.apply(state: state)
            }

            creationVM.onRequestImagePicker = { [weak self] maxCount in
                guard let self else { return }
                
                Task {
                    let result = await PermissionService.shared.requestPhotoLibraryPermission()
                    
                    switch result {
                    case .granted:
                        self.presentPicker(maxCount: maxCount)
                        
                    case .denied:
                        PermissionService.shared.showGoToSettingsAlert(
                            from: self,
                            title: "Нет доступа к Фото.",
                            message: "Разрешите доступ к Фото в Настройках, чтобы выбирать изображения."
                        )
                        
                    case .unavailable:
                        self.showAlert(message: "Фото недоступны на этом устройстве.")
                    }
                }
            }

            creationVM.onCloseAfterPublish = { [weak self] in
                guard let self else { return }
                // Собрать UIImage из Data и уведомлить делегата
                let images = creationVM
                    .allImageDatas()
                    .compactMap { UIImage(data: $0) }
                self.delegate?.storyCreationDidPublish(self, items: images)
            }

            creationVM.onError = { [weak self] error in
                self?.showAlert(message: error.localizedDescription)
            }

            creationVM.onTickProgress = { [weak self] progress in
                self?.updateCurrentProgress(progress)
            }

            creationVM.onStoryShouldClose = { [weak self] in
                self?.dismiss(animated: true)
            }

        } else if let playerVM = playerViewModel {
            // ===== РЕЖИМ ПРОСМОТРА =====
            playerVM.onStateChange = { [weak self] state in
                guard let self else { return }
                self.currentState = state
                self.apply(state: state)
            }

            playerVM.onTickProgress = { [weak self] progress in
                self?.updateCurrentProgress(progress)
            }

            playerVM.onStoryShouldClose = { [weak self] in
                self?.dismiss(animated: true)
            }

            playerVM.onMetaUpdated = { [weak self] createdAt in
                self?.updateMeta(createdAt: createdAt)
            }

            playerVM.onRelativeTimeUpdated = { [weak self] text in
                self?.dateLabel.text = text
            }
        }
    }

    private func callViewModelViewDidLoad() {
        if let creationVM = creationViewModel {
            creationVM.viewDidLoad()
        } else if let playerVM = playerViewModel {
            Task { await playerVM.viewDidLoad() }
        }
    }

    /// Применяет новое состояние к UI:  пересоздает прогресс‑бары; выбирает текущий слайд;  обновляет кнопку публикации (в режиме создания).
    private func apply(state: StoryState) {
        configureProgressBars(count: state.itemsCount)
        updateProgressHighlight(currentIndex: state.currentIndex)

        let data: Data?
        if let creationVM = creationViewModel {
            data = creationVM.currentImageData()
        } else if let playerVM = playerViewModel {
            data = playerVM.currentImageData()
        } else {
            data = nil
        }

        imageView.image = data.flatMap { UIImage(data: $0) }

        if mode == .create {
            // В режиме создания кнопка "Опубликовать" активна только при наличии слайдов и когда VM не в состоянии busy (идёт публикация).
            let hasItems = state.itemsCount > 0
            let enabled = hasItems && !state.isBusy

            publishButton.isHidden = false
            publishButton.isEnabled = enabled

            if enabled {
                // Здесь можно заиспользовать брендовый цвет вместо systemBlue.
                publishButton.setTitleColor(.appAccent, for: .normal)
            } else {
                publishButton.setTitleColor(.appSecondaryText, for: .normal)
            }
        }
    }

    /// Создает прогресс‑бары по количеству слайдов.
    private func configureProgressBars(count: Int) {
        progressStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        progressViews.removeAll()

        guard count > 0 else { return }

        for _ in 0..<count {
            let bar = UIProgressView(progressViewStyle: .default)
            bar.progressTintColor = .white
            bar.trackTintColor = UIColor.white.withAlphaComponent(0.3)
            bar.progress = 0.0
            progressViews.append(bar)
            progressStackView.addArrangedSubview(bar)
        }
    }

    /// Обновляет "заливку" прогресс‑баров: все до текущего индекса = 1.0;  текущий — сбрасываем под анимацию таймера; остальные — 0.
    private func updateProgressHighlight(currentIndex: Int) {
        for (index, bar) in progressViews.enumerated() {
            if index < currentIndex {
                bar.progress = 1.0
            } else if index == currentIndex {
                bar.progress = 0.0
            } else {
                bar.progress = 0.0
            }
        }
    }

    /// Обновляет прогресс текущего бара по тикам таймера.
    private func updateCurrentProgress(_ progress: Double) {
        guard
            let state = currentState,
            state.currentIndex < progressViews.count
        else { return }

        progressViews[state.currentIndex].progress = Float(progress)
    }

    /// Обновляет шапку в режиме просмотра: имя/аватар/время.
    private func updateMeta(createdAt: Date?) {
        nameLabel.text = userName

        guard
            let urlString = avatarURLString,
            let url = URL(string: urlString)
        else { return }

        Task { [weak self] in
            guard let self else { return }
            let image = await ImageLoader.shared.loadImage(from: url)
            if let image {
                self.avatarImageView.image = image
            }
        }
    }

    /// Кнопка закрытия: в режиме создания дергает делегата (для сброса флагов и переходов); в режиме просмотра просто dismiss.
    @objc private func didTapClose() {
        if mode == .create {
            delegate?.storyCreationDidCancel(self)
        } else {
            dismiss(animated: true)
        }
    }

    /// Кнопка "Опубликовать" - инициирует сохранение в storage через VM.
    @objc private func didTapPublish() {
        guard mode == .create, let creationVM = creationViewModel else { return }
        Task { await creationVM.didTapPublish() }
    }

    /// Тап по кнопке "Добавить" - показывает action sheet с вариантами: галерея (через PHPicker), камера (через UIImagePicker).
    @objc private func didTapAdd() {
        guard mode == .create, let creationVM = creationViewModel else { return }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let gallery = UIAlertAction(title: "Выбрать из галереи", style: .default) { [weak creationVM] _ in
            creationVM?.didTapAddImages()
        }
        
        let camera = UIAlertAction(title: "Сделать фото", style: .default) { [weak self] _ in
            guard let self else { return }
            
            Task {
                let result = await PermissionService.shared.requestCameraPermission()
                
                switch result {
                case .granted:
                    self.presentCamera()
                    
                case .denied:
                    PermissionService.shared.showGoToSettingsAlert(
                        from: self,
                        title: "Нет доступа к камере устройства.",
                        message: "Разрешите доступ к камере в Настройках, чтобы делать фото."
                    )
                    
                case .unavailable:
                    self.showAlert(message: "Камера недоступна на этом устройстве.")
                }
            }
        }
        
        let cancel = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
        
        alert.addAction(gallery)
        alert.addAction(camera)
        alert.addAction(cancel)
        
        present(alert, animated: true)
    }

    /// Удалить текущий слайд (режим создания).
    @objc private func didTapDeleteCurrent() {
        guard mode == .create, let creationVM = creationViewModel else { return }
        creationVM.didTapDeleteCurrent()
    }

    /// Тап справа — переключение к следующему слайду или закрытие, на последнем слайде в режиме просмотра.
    @objc private func didTapRight(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: view)
        guard point.x >= view.bounds.width / 2 else { return }

        if let state = currentState,
           state.currentIndex >= state.itemsCount - 1,
           mode == .viewOnly {
            // На последнем фото - закрываем экран
            dismiss(animated: true)
            return
        }

        if let creationVM = creationViewModel {
            creationVM.goToNext()
        } else if let playerVM = playerViewModel {
            playerVM.goToNext()
        }
    }

    /// Свайп вниз — жест "закрыть историю".
    @objc private func didSwipeDown(_ gesture: UISwipeGestureRecognizer) {
        didTapClose()
    }

    /// Открывает камеру через UIImagePickerController.
    private func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = false
        present(picker, animated: true)
    }

    /// Открывает системный PHPicker для выбора  фото.
    private func presentPicker(maxCount: Int) {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = maxCount
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate

extension StoryViewController: PHPickerViewControllerDelegate {
 
    func picker(
        _ picker: PHPickerViewController,
        didFinishPicking results: [PHPickerResult]
    ) {
        picker.dismiss(animated: true)

        guard mode == .create,
              let creationVM = creationViewModel,
              !results.isEmpty else { return }

        var datas: [Data] = []
        let group = DispatchGroup()

        for result in results {
            guard result.itemProvider.canLoadObject(ofClass: UIImage.self) else { continue }

            group.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                defer { group.leave() }

                guard
                    let image = object as? UIImage,
                    error == nil,
                    let data = image.jpegData(compressionQuality: 0.9)
                else { return }

                datas.append(data)
            }
        }

        group.notify(queue: .main) {
            guard !datas.isEmpty else { return }
            creationVM.didPick(imageDatas: datas)
        }
    }
}

// MARK: - UIImagePickerControllerDelegate

extension StoryViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
   
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        picker.dismiss(animated: true)

        guard mode == .create,
              let creationVM = creationViewModel,
              let image = info[.originalImage] as? UIImage,
              let data = image.jpegData(compressionQuality: 0.9) else { return }

        creationVM.didPick(imageDatas: [data])
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
