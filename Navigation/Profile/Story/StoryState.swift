import Foundation

/// Универсальный стейт для обоих VM (создание и просмотр истории).
struct StoryState {
    /// Сырые данные изображений  по порядку.
    var items: [Data]
    /// Индекс текущего отображаемого слайда.
    var currentIndex: Int
    /// Флаг фоновой активности: для `Player`  может используется при загрузке из storage; для `Creation` во время публикации истории.
    var isBusy: Bool
    /// Дата создания истории (для показа "N сек./мин.  назад").
    var createdAt: Date?
    /// Геттер количества элементов.
    var itemsCount: Int { items.count }
}
