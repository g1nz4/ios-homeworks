import Foundation

/// ViewModel для работы со сторис в ленте.
@MainActor
final class FeedStoriesViewModel {

    /// ID текущего пользователя, для которого грузим сторис
    private let currentUserId: String
    /// Сервис, отвечающий за загрузку сторис (локальный )
    private let storyService: LocalStoryServiceProtocol

    /// Текущий список сторис, подготовленный для отображения
    private(set) var stories: [FeedStory] = []

    /// Коллбэк, вызывается при изменении stories.
    var onStoriesUpdated: (([Int]) -> Void)?

    init(currentUserId: String, storyService: LocalStoryServiceProtocol) {
        self.currentUserId = currentUserId
        self.storyService = storyService
    }

    /// Асинхронная загрузка сторис для текущего пользователя
    func load() async {
        do {
            // Получить сторис от сервиса
            let loaded = try await storyService.fetchStories(for: currentUserId)

            // Сортировка по дате
            let sortedStories = loaded.sorted { $0.createdAt > $1.createdAt }

            // Для каждой сторис дополнительно сортировать ее items (слайды)
            let withSortedItems = sortedStories.map { story -> FeedStory in
                var s = story
                s.items = story.items.sorted { $0.id < $1.id }
                return s
            }

            // Обновить состояние view‑model
            self.stories = withSortedItems

            // Уведомить UI, что обновились все сторис
            onStoriesUpdated?(Array(self.stories.indices))
        } catch {
            // Пока логирование ошибки
            AppLogger.error("Stories load error: \(error)")
        }
    }

    /// Количество сторис для коллекции/таблицы
    func numberOfItems() -> Int { stories.count }

    /// Модель сторис по индексу
    func story(at index: Int) -> FeedStory { stories[index] }

    /// Пометить сторис как просмотренную по индексу
    func markViewed(at index: Int) {
        // Защита от выхода за пределы массива
        guard stories.indices.contains(index) else { return }
        // Если уже просмотрена — ничего не делать
        guard !stories[index].isViewed else { return }

        // Обновить локальную модель в памяти view‑model
        stories[index].isViewed = true

        (storyService as? LocalStoryService)?.markViewed(storyId: stories[index].id)

        // Уведомить UI, что обновился элемент
        onStoriesUpdated?([index])
    }
}
