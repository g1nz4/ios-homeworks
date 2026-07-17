import Foundation
import Network

/// Протокол сервиса статуса сети. (для тестов)
protocol NetworkStatusServiceProtocol: AnyObject {
    /// Текущее состояние подключения к сети: true  – есть интернет (path.status == .satisfied), false – сеть недоступна.
    var isConnected: Bool { get }
}

/// Сервис, отслеживающий состояние сети с помощью NWPathMonitor.
final class NetworkStatusService: NetworkStatusServiceProtocol {
    
    static let shared = NetworkStatusService()
    
    /// Системный монитор сетевого пути (Wi‑Fi / сотовая сеть / нет сети).
    private let monitor: NWPathMonitor
    /// Очередь, на которой NWPathMonitor будет присылать обновления.
    private let queue = DispatchQueue(label: "NetworkStatusService.queue")
    /// Внутреннее хранилище статуса сети.
    private var _isConnected: Bool = true
    /// Замок для потокобезопасного доступа к `_isConnected`.
    private let lock = NSLock()
    /// Публичное свойство статуса сети.
    var isConnected: Bool {
        lock.lock()
        let value = _isConnected
        lock.unlock()
        return value
    }
    
    private init() {
        monitor = NWPathMonitor()
        // Коллбэк вызывается при каждом изменении сетевого пути
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            // Сеть есть, если статус пути == .satisfied
            let connected = (path.status == .satisfied)
            // Обновить внутренний флаг под замком
            self.lock.lock()
            self._isConnected = connected
            self.lock.unlock()
        }
        // Запуск мониторинга на отдельной очереди
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}
