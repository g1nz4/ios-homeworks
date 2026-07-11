import Foundation
import StorageService

/// ViewModel для экрана публикации поста.
/// Отвечает за валидацию текста/картинки и событие "можно публиковать".
final class PublishPostViewModel {

    /// Текст поста (как есть, без тримминга).
    private(set) var text: String = "" {
        didSet { onTextChanged?(text) }
    }

    /// Выбрано ли какое‑то изображение.
    private(set) var hasImage: Bool = false {
        didSet { onHasImageChanged?(hasImage) }
    }

    /// Сообщает об изменении текста.
    var onTextChanged: ((String) -> Void)?

    /// Сообщает, что наличие картинки изменилось.
    var onHasImageChanged: ((Bool) -> Void)?

    /// Можно ли сейчас нажать кнопку "Опубликовать".
    var onCanPublishChanged: ((Bool) -> Void)?

    /// Сообщает наружу, что можно публиковать.
    var onPublish: ((String) -> Void)?

    /// Ошибки валидации.
    var onError: ((String) -> Void)?

    /// Обновляет текст поста.
    func updateText(_ newText: String) {
        text = newText
        validate()
    }

    /// Обновляет флаг наличия картинки.
    func updateHasImage(_ hasImage: Bool) {
        self.hasImage = hasImage
        validate()
    }

    /// Обработка нажатия на кнопку "Опубликовать".
    func didTapPublish() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasText = !trimmed.isEmpty

        guard hasText || hasImage else {
            onError?("Добавьте текст или картинку")
            return
        }

        onPublish?(trimmed)
    }

    /// Пересчитывает, можно ли публиковать (кнопка Done).
    private func validate() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasText = !trimmed.isEmpty
        let canPublish = hasText || hasImage
        onCanPublishChanged?(canPublish)
    }
}
