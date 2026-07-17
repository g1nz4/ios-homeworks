import Foundation

/// ViewModel для экрана публикации поста.
/// Отвечает за валидацию текста/картинки и событие "можно публиковать".
final class PublishPostViewModel {

    private let postService: PostService
    private let user: User
    
    let editingPost: MyPost?
    
    /// Текст поста (как есть, без тримминга).
    private(set) var text: String = "" {
        didSet { onTextChanged?(text) }
    }

    /// Выбрано ли какое‑то изображение.
    private(set) var hasImage: Bool = false {
        didSet { onHasImageChanged?(hasImage) }
    }
    
    /// Заголовок экрана (зависит от режима: новый/редактирование).
    private(set) var screenTitle: String

    /// Сообщает об изменении текста.
    var onTextChanged: ((String) -> Void)?

    /// Сообщает, что наличие картинки изменилось.
    var onHasImageChanged: ((Bool) -> Void)?

    /// Можно ли сейчас нажать кнопку "Опубликовать".
    var onCanPublishChanged: ((Bool) -> Void)?

    /// Сообщает наружу, что можно публиковать.
    var onPublish: ((MyPost) -> Void)?

    /// Ошибки валидации.
    var onError: ((String) -> Void)?
    
    init(
        postService: PostService,
        user: User,
        editingPost: MyPost? = nil
    ) {
        self.postService = postService
        self.user = user
        self.editingPost = editingPost
        self.screenTitle = editingPost == nil ? "Новый пост" : "Редактировать пост"
        
        if let post = editingPost {
            self.text = post.description
            self.hasImage = post.image != nil
        }
    }

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
    func didTapPublish(selectedImageData: Data?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasText = !trimmed.isEmpty
        let hasImage = (selectedImageData != nil)
        
        guard hasText || hasImage else {
            onError?("Добавьте текст или картинку")
            return
        }
        
        if var original = editingPost {
            original.description = trimmed
            original.image = selectedImageData
            
            Task {
                do {
                    let saved = try await postService.updatePost(original)
                    await MainActor.run { self.onPublish?(saved) }
                } catch {
                    await MainActor.run { self.onError?("Не удалось сохранить изменения") }
                }
            }
        } else {
            // создание нового поста
            let newPost = MyPost(
                id: UUID().uuidString,
                authorId: user.id,
                author: user.name.displayName,
                image: selectedImageData,
                description: trimmed,
                likes: 0,
                views: 0
            )
            
            Task {
                await MainActor.run { self.onPublish?(newPost) }
            }
        }
    }

    /// Пересчитывает, можно ли публиковать (кнопка Done).
    private func validate() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasText = !trimmed.isEmpty
        let canPublish = hasText || hasImage
        onCanPublishChanged?(canPublish)
    }
}
