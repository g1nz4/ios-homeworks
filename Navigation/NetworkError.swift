import Foundation

enum NetworkError: String, Error {
    case requestFailed = "Запрос не выполнен"
    case errorReceivingData = "Ошибка получения данных из сети"
    case noData = "Нет данных"
    case decodingFailed = "Не удалось расшифровать данные"
    case invalidURL = "Неверный URL"
}
