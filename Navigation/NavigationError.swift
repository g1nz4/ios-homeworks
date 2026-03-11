import Foundation

enum NavigationError: String, Error {
    case emptyCredentials = "Введите логин и пароль."
    case invalidCredentials = "Неверный логин или пароль."
    case userNotFound = "Пользователь не найден."
    case feedLoadingFailed = "Не удалось загрузить ленту новостей."
    case feedUpdateFailed = "Не удалось обновить ленту. Попробуйте позже."
    case profileLoadingFailed = "Не удалось загрузить данные профиля."
    case statusUpdateFailed = "Не удалось обновить статус."
    case fileNotFound = "Файл не найден."
    case errorAVAudioPlayer = "Ошибка AVAudioPlayer."
}

