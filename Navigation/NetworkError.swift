import Foundation

enum NetworkError: Error {
    case requestFailed(Error)
    case errorReceivingData
    case noData
    case decodingFailed
}
