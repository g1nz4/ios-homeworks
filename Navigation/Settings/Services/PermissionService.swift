import UIKit
import AVFoundation
import Photos

/// Протокол сервиса, который: запрашивает системные разрешения (камера, фотобиблиотека) и показывает алерты с предложением перейти в настройки.
protocol PermissionServicing: AnyObject {

    /// Запрос разрешения на доступ к камере с возможностью сразу показать алерт.
    func requestCameraPermission(
        from presenter: UIViewController,
        completion: @escaping (PermissionService.PermissionResult) -> Void
    )

    /// Запрос разрешения на доступ к фотобиблиотеке.
    func requestPhotoLibraryPermission(
        from presenter: UIViewController,
        completion: @escaping (PermissionService.PermissionResult) -> Void
    )

    /// Презентует алерт с предложением перейти в настройки приложения.
    func showGoToSettingsAlert(
        from presenter: UIViewController,
        title: String,
        message: String
    )
}

/// Сервис работы с системными разрешениями: камера, фотобиблиотека, показ алерта с переходом в настройки.
final class PermissionService {

    /// Унифицированный результат проверки / запроса разрешения.
    enum PermissionResult {
        /// Разрешено.
        case granted
        /// Пользователь отказал или доступ ограничен.
        case denied
        /// Функция недоступна.
        case unavailable
    }

    /// Глобальный экземпляр сервиса.
    static let shared = PermissionService()

    private init() {}

    /// Запрашивает доступ к камере.
    func requestCameraPermission() async -> PermissionResult {
        // Доступен ли источник
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            return .unavailable
        }

        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            // Уже есть доступ
            return .granted

        case .notDetermined:
            // Статус ещё не определён — показать системный диалог
            let granted = await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    continuation.resume(returning: granted)
                }
            }
            return granted ? .granted : .denied

        case .denied, .restricted:
            // Пользователь отказал / доступ ограничен настройками устройства
            return .denied

        @unknown default:
            return .denied
        }
    }

    /// Запрашивает доступ к медиатеке (фото).
    func requestPhotoLibraryPermission() async -> PermissionResult {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch status {
        case .authorized, .limited:
            // Есть полный или ограниченный доступ
            return .granted

        case .notDetermined:
            // Первый запрос — показать системный диалог
            let newStatus = await withCheckedContinuation { continuation in
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    continuation.resume(returning: status)
                }
            }

            switch newStatus {
            case .authorized, .limited:
                return .granted
            case .denied, .restricted:
                return .denied
            case .notDetermined:
                return .denied
            @unknown default:
                return .denied
            }

        case .denied, .restricted:
            // Пользователь уже отказал / доступ ограничен
            return .denied

        @unknown default:
            return .denied
        }
    }

    /// Текущий статус доступа к камере без запроса разрешения.
    func currentCameraPermissionStatus() async -> PermissionResult {
        // Доступен ли вообще источник
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            return .unavailable
        }

        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            return .granted
        case .notDetermined:
            return .denied
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .denied
        }
    }

    /// Текущий статус доступа к фотобиблиотеке без запроса разрешения.
    func currentPhotoLibraryPermissionStatus() async -> PermissionResult {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch status {
        case .authorized, .limited:
            return .granted
        case .notDetermined:
            // Разрешение ещё не запрошено
            return .denied
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .denied
        }
    }

    /// Показывает `UIAlertController` с предложением открыть настройки приложения, если пользователь запретил доступ к камере/фото.
    func showGoToSettingsAlert(
        from presenter: UIViewController,
        title: String,
        message: String
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: "Отмена",
                style: .cancel
            )
        )

        alert.addAction(
            UIAlertAction(
                title: "Открыть настройки",
                style: .default
            ) { _ in
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
        )

        presenter.present(alert, animated: true)
    }
}

// MARK: - PermissionServicing 

extension PermissionService: PermissionServicing {
    func requestCameraPermission(
        from presenter: UIViewController,
        completion: @escaping (PermissionService.PermissionResult) -> Void
    ) {
        Task {
            let result = await requestCameraPermission()
            completion(result)
        }
    }

    func requestPhotoLibraryPermission(
        from presenter: UIViewController,
        completion: @escaping (PermissionService.PermissionResult) -> Void
    ) {
        Task {
            let result = await requestPhotoLibraryPermission()
            completion(result)
        }
    }
}
