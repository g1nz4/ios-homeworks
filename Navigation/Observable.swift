import Foundation

final class Observable<T> {
    private var listener: ((T) -> Void)?
    
    var value: T {
        didSet { listener?(value) }
    }
    
    init(_ value: T) {
        self.value = value
    }
    
    func binding(_ listener: @escaping (T) -> Void) {
        self.listener = listener
        listener(value)
    }
}
