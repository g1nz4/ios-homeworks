import Foundation
@testable import Navigation

/// Мок сервиса, который сообщает, есть ли интернет.
final class NetworkStatusServiceMock: NetworkStatusServiceProtocol {
    var isConnected: Bool = true
}
