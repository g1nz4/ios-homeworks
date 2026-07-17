import UIKit
import PhotosUI

protocol PublishPostViewControllerDelegate: AnyObject {
    func publishPostViewController(_ vc: PublishPostViewController, didCreate post: MyPost)
    func publishPostViewController(_ vc: PublishPostViewController, didEdit post: MyPost)
}

/// Экран создания/редактирования поста: текст + опциональная картинка.
final class PublishPostViewController: BaseScrollViewController {

    weak var coordinator: ProfileCoordinator?
    weak var delegate: PublishPostViewControllerDelegate?
    weak var secondaryDelegate: PublishPostViewControllerDelegate?

    private let viewModel: PublishPostViewModel

    private var imageViewHeightConstraint: NSLayoutConstraint!

    /// Выбранная пользователем картинка (если есть).
    private var selectedImage: UIImage? {
        didSet {
            imageView.image = selectedImage
            let hasImage = (selectedImage != nil)

            imageView.isHidden = !hasImage
            changePhotoButton.isHidden = !hasImage

            imageViewHeightConstraint.constant = hasImage ? 220 : 0
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }

            viewModel.updateHasImage(hasImage)
        }
    }

    /// Основное текстовое поле для поста.
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.backgroundColor = .appBackground
        textView.delegate = self
        textView.keyboardType = .default
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        
        return textView
    }()

    /// Плейсхолдер внутри textView.
    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Напишите что‑нибудь…"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .appSecondaryText
        
        return label
    }()

    /// Превью выбранной картинки поста.
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.isHidden = true
        
        return imageView
    }()

    /// Кнопка удаления выбранной картинки.
    private lazy var changePhotoButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .appBackground
        button.backgroundColor = UIColor.appPrimaryText.withAlphaComponent(0.4)
        button.layer.cornerRadius = 14
        button.clipsToBounds = true
        button.isHidden = true
        button.addTarget(self, action: #selector(didTapRemovePhoto), for: .touchUpInside)
       
        return button
    }()

    private var publishBarButtonItem: UIBarButtonItem!

    /// Кнопка "Готово" в accessory над клавиатурой.
    private lazy var accessoryDoneButton: PrimaryActionButton = {
        let button = PrimaryActionButton(title: "Готово")
        button.setAction { [weak self] in
            self?.didTapKeyboardDone()
        }
        button.layer.cornerRadius = 20
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        button.widthAnchor.constraint(equalToConstant: 100).isActive = true
        
        return button
    }()

    /// Кнопка открытия галереи.
    private lazy var galleryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "photo.on.rectangle"), for: .normal)
        button.tintColor = .app
        button.addTarget(self, action: #selector(didTapGallery), for: .touchUpInside)
        
        return button
    }()

    /// Кнопка открытия камеры.
    private lazy var cameraButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "camera"), for: .normal)
        button.tintColor = .app
        button.addTarget(self, action: #selector(didTapCamera), for: .touchUpInside)
        
        return button
    }()

    /// Контейнер для элементов accessoryView над клавиатурой.
    private lazy var accessoryViewContainer: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 60))
        view.backgroundColor = .appBackground

        [galleryButton, cameraButton, accessoryDoneButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            galleryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            galleryButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            cameraButton.leadingAnchor.constraint(equalTo: galleryButton.trailingAnchor, constant: 16),
            cameraButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            accessoryDoneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            accessoryDoneButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        return view
    }()

    init(viewModel: PublishPostViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.screenTitle

        setupNavigationBar()
        bindViewModel()
        configureInitialState()
        textView.inputAccessoryView = accessoryViewContainer
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }

    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(didTapClose)
        )

        publishBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(didTapPublish)
        )
        publishBarButtonItem.isEnabled = false
        publishBarButtonItem.tintColor = .app
        navigationItem.rightBarButtonItem = publishBarButtonItem
    }

    override func configureContent() {
        super.configureContent()
       
        [imageView, changePhotoButton, textView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        textView.addSubview(placeholderLabel)
  
        imageViewHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            imageViewHeightConstraint,

            changePhotoButton.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 8),
            changePhotoButton.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -8),
            changePhotoButton.widthAnchor.constraint(equalToConstant: 28),
            changePhotoButton.heightAnchor.constraint(equalToConstant: 28),

            textView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),

            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 8),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 5),
            placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor)
        ])
    }

    /// Конфигурация для режима "редактировать пост".
    private func configureInitialState() {
        if let post = viewModel.editingPost {
            textView.text = post.description
            placeholderLabel.isHidden = !post.description.isEmpty
            viewModel.updateText(post.description)
            
            if let data = post.image, let image = UIImage(data: data) {
                selectedImage = image
            } else {
                selectedImage = nil
            }
        } else {
            selectedImage = nil
        }
    }

    private func bindViewModel() {
        viewModel.onCanPublishChanged = { [weak self] canPublish in
            self?.publishBarButtonItem?.isEnabled = canPublish
        }

        viewModel.onPublish = { [weak self] post in
            guard let self else { return }
            
            if self.viewModel.editingPost != nil {
                self.delegate?.publishPostViewController(self, didEdit: post)
                self.secondaryDelegate?.publishPostViewController(self, didEdit: post)
            } else {
                self.delegate?.publishPostViewController(self, didCreate: post)
                self.secondaryDelegate?.publishPostViewController(self, didCreate: post)
            }
            
            self.coordinator?.dismiss()
        }

        viewModel.onError = { [weak self] message in
            self?.showAlert(message: message)
        }
    }
    
    private func presentPhotoPicker() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        picker.modalPresentationStyle = .pageSheet
        present(picker, animated: true)
    }

    private func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    @objc private func didTapGallery() {
        Task {
            let result = await PermissionService.shared.requestPhotoLibraryPermission()

            await MainActor.run { [weak self] in
                guard let self else { return }

                switch result {
                case .granted:
                    self.presentPhotoPicker()

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
    }

    @objc private func didTapCamera() {
        Task {
            let result = await PermissionService.shared.requestCameraPermission()

            await MainActor.run { [weak self] in
                guard let self else { return }

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
    }

    @objc private func didTapPublish() {
        let imageData: Data?
        if let image = selectedImage {
            imageData = image.pngData()
        } else {
            imageData = nil
        }
        
        viewModel.didTapPublish(selectedImageData: imageData)
    }

    @objc private func didTapKeyboardDone() {
        view.endEditing(true)
    }

    @objc private func didTapRemovePhoto() {
        selectedImage = nil
    }

    @objc private func didTapClose() {
        coordinator?.dismiss()
    }
}

// MARK: - UITextViewDelegate

extension PublishPostViewController: UITextViewDelegate {
 
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        viewModel.updateText(textView.text)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension PublishPostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        defer { picker.dismiss(animated: true) }

        let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
        if let image { selectedImage = image }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate

extension PublishPostViewController: PHPickerViewControllerDelegate {
    func picker(
        _ picker: PHPickerViewController,
        didFinishPicking results: [PHPickerResult]
    ) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let self, let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self.selectedImage = image
            }
        }
    }
}
