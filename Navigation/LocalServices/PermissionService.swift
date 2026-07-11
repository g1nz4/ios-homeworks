import UIKit
import AVFoundation
import Photos

/// Протокол сервиса, который запрашивает permissions и показывает алерты.
protocol PermissionServicing: AnyObject {
    /// Запрос разрешения на доступ к камере.
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

/// Сервис работы с системными разрешениями (камера, фото).
final class PermissionService {
    
    /// Унифицированный результат проверки / запроса разрешения.
    enum PermissionResult {
        /// Разрешено.
        case granted
        /// Пользователь отказал или доступ ограничен.
        case denied
        /// Нет доступа.
        case unavailable
    }
    
    static let shared = PermissionService()
    private init() {}
    
    /// Запрашивает доступ к камере.
    func requestCameraPermission() async -> PermissionResult {
        // Доступен ли вообще источник
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            return .unavailable
        }
        
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            // Уже есть доступ
            return .granted
            
        case .notDetermined:
            // Статус ещё не определён - запрос у пользователя
            let granted = await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    continuation.resume(returning: granted)
                }
            }
            return granted ? .granted : .denied
            
        case .denied, .restricted:
            // Пользователь уже отказал / доступ ограничен настройками устройства
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
            // Пользователь уже отказал / доступ ограничен настройками устройства
            return .denied
            
        @unknown default:
            return .denied
        }
    }
    
    /// Показывает UIAlertController с предложением открыть настройки приложения, если пользователь запретил доступ к камере/фото.
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
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Открыть настройки", style: .default) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        })
        
        presenter.present(alert, animated: true)
    }
}
