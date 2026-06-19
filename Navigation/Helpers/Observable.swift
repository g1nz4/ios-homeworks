import Foundation

/// Простая обёртка над значением, позволяющая подписаться на его изменения.
final class Observable<T> {
    
    /// Замыкание‑подписчик, которое вызывается при каждом изменении "value".
    private var listener: ((T) -> Void)?
    
    /// Хранимое значение, при установке нового значения вызываем текущего "listener".
    var value: T {
        didSet { listener?(value) }
    }
    
    init(_ value: T) {
        self.value = value
    }
    
    /// Подписка на изменения значения.
    /// Параметр listener: замыкание, которое будет вызываться: сразу при подписке (с текущим "value") и каждый раз при дальнейшем изменении "value"..
    func binding(_ listener: @escaping (T) -> Void) {
        self.listener = listener
        // Сразу уведомляем подписчика о текущем значении
        listener(value)
    }
    
    deinit {
        // Обнулить listener, чтобы разорвать возможные retain‑циклы
        listener = nil
    }
}
