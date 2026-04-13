import Foundation

enum NavigationError: String, Error {
    case emptyCredentials = "Введите логин и пароль."
    case invalidCredentials = "Неверный логин или пароль."
    case weakPassword = "Пароль должен содержать минимум 6 символов."
    case invalidEmail = "Некорректный email."
    case passwordsDoNotMatch = "Пароли не совпадают."
    case feedLoadingFailed = "Не удалось загрузить ленту новостей."
    case feedUpdateFailed = "Не удалось обновить ленту. Попробуйте позже."
    case profileLoadingFailed = "Не удалось загрузить данные профиля."
    case statusUpdateFailed = "Не удалось обновить статус."
    case fileNotFound = "Файл не найден."
    case errorAVAudioPlayer = "Ошибка AVAudioPlayer."
    case favoritesSavingFailed = "Не удалось сохранить в избранное"
    case favoritesLoadingFailed = "Ошибка загрузки данных избранных постов"
}

