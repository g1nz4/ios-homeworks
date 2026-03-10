import Foundation

enum NavigationError: Error {
    case emptyCredentials
    case invalidCredentials
    case userNotFound
    case feedLoadingFailed
    case feedUpdateFailed
    case profileLoadingFailed
    case statusUpdateFailed
}

extension NavigationError: LocalizedError {
   
    var errorDescription: String? {
        switch self {
        case .emptyCredentials:
            return "Введите логин и пароль."
        case .invalidCredentials:
            return "Неверный логин или пароль."
        case .userNotFound:
            return "Пользователь не найден."
        case .feedLoadingFailed:
            return "Не удалось загрузить ленту новостей."
        case .feedUpdateFailed:
            return "Не удалось обновить ленту. Попробуйте позже."
        case .profileLoadingFailed:
            return "Не удалось загрузить данные профиля."
        case .statusUpdateFailed:
            return "Не удалось обновить статус."
        }
    }
}
