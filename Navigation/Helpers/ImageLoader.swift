import UIKit

/// Синглтон для загрузки изображений по URL с in‑memory кешем.
/// Используется по всему приложению для подгрузки картинок из сети.
final class ImageLoader {

    static let shared = ImageLoader()

    /// Кеш изображений в памяти. Ключ — NSURL, значение — UIImage.
    private let cache = NSCache<NSURL, UIImage>()

    private init() {}

    /// Загружает изображение по URL.
    /// Порядок действий: Проверяет in‑memory кеш; если картинка есть, то сразу возвращает. Если нет - ходит в сеть через `URLSession.shared.data(from:)`.  Преобразует полученные данные в `UIImage` и кладёт в кеш.
    func loadImage(from url: URL) async -> UIImage? {
        // Проверка кеша
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }

        // Загрузка данных из сети
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            // Превращение данных в UIImage
            guard let image = UIImage(data: data) else {
                return nil
            }
            // Сохранение в кеш
            cache.setObject(image, forKey: url as NSURL)
            return image
        } catch {
            return nil
        }
    }
    
    /// Параллельно загружает изображения для всех `story.items`  и возвращает массив JPEG‑данных успешно загруженных картинок.
    func loadImages(for story: FeedStory) async -> [Data] {
        await withTaskGroup(of: (Int, Data?).self) { group in
            for (index, item) in story.items.enumerated() {
                group.addTask { [self] in
                    guard let url = URL(string: item.imageURL) else {
                        return (index, nil)
                    }
                    let img = await self.loadImage(from: url)
                    return (index, img?.jpegData(compressionQuality: 0.9))
                }
            }

            var tmp: [Int: Data] = [:]

            for await (index, data) in group {
                if let data {
                    tmp[index] = data
                }
            }

            // Восстановить массив в порядке индексов items
            var result: [Data] = []
            result.reserveCapacity(story.items.count)
            for i in 0..<story.items.count {
                if let data = tmp[i] {
                    result.append(data)
                }
            }

            return result
        }
    }
}
