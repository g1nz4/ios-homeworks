import Foundation

/// Простая обёртка над значением, позволяющая подписаться на его изменения.
final class Observable<T> {
    typealias Listener = (T) -> Void
    /// Замыкание‑подписчик, которое вызывается при каждом изменении "value".
    private var listeners: [UUID: Listener] = [:]
    
    /// Хранимое значение, при установке нового значения вызываем текущего "listener".
    var value: T {
        didSet { notify() }
    }
    
    init(_ value: T) {
        self.value = value
    }
    
    /// Подписка на изменения значения.
    /// Параметр listener: замыкание, которое будет вызываться: сразу при подписке (с текущим "value") и каждый раз при дальнейшем изменении "value"..
    @discardableResult
    func binding(_ listener: @escaping Listener) -> UUID {
        let id = UUID()
        listeners[id] = listener
        listener(value)
        return id
    }
    
    func removeBinding(id: UUID) {
        listeners.removeValue(forKey: id)
    }

    private func notify() {
        for listener in listeners.values {
            listener(value)
        }
    }
}
