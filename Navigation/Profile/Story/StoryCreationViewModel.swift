import Foundation

/// ViewModel для режима СОЗДАНИЯ истории.
/// Отвечает за:  управление списком выбранных картинок (add/delete/next/prev);  ограничение по количеству слайдов;  публикацию истории в storage; запуск/остановку таймера прогресса для текущего слайда.
@MainActor
final class StoryCreationViewModel {

    // MARK: - Outputs (callbacks в сторону ViewController)

    /// Полный стейт (список Data, индекс, busy/flg).
    var onStateChange: ((StoryState) -> Void)?

    /// Отдельный коллбек на изменение массива картинок.
    var onImagesUpdated: (([Data]) -> Void)?

    /// Запрос на показ системного пикера картинок (галерея).
    /// Параметр — максимальное количество картинок, которое ещё можно добавить.
    var onRequestImagePicker: ((Int) -> Void)?

    /// Сигнал, что публикация завершилась успешно и экран можно закрыть.
    var onCloseAfterPublish: (() -> Void)?

    /// Ошибки (например, при сохранении в storage).
    var onError: ((Error) -> Void)?

    /// Прогресс текущего слайда [0, 1] — для прогресс‑бара.
    var onTickProgress: ((Double) -> Void)?

    /// Сигнал на закрытие истории..
    var onStoryShouldClose: (() -> Void)?

    private var state: StoryState
    private let timer: StoryTimerProtocol
    private let itemDuration: TimeInterval
    private let maxItems: Int

    private let storage: CDStoryStorageProtocol
    private let userId: String

    init(
        maxItems: Int = 10,
        itemDuration: TimeInterval = 5.0,
        timer: StoryTimerProtocol,
        storage: CDStoryStorageProtocol,
        userId: String
    ) {
        self.state = StoryState(items: [], currentIndex: 0, isBusy: false, createdAt: nil)
        self.timer = timer
        self.maxItems = maxItems
        self.itemDuration = itemDuration
        self.storage = storage
        self.userId = userId
    }

    /// Отдает начальное состояние (пустой список).
    func viewDidLoad() {
        emitState()
        emitImages()
    }

    /// Остановка таймера при уходе с экрана.
    func stopTimer() {
        timer.stop()
    }
    
    /// Текущее изображение.
    func currentImageData() -> Data? {
        guard state.currentIndex < state.itemsCount else { return nil }
        return state.items[state.currentIndex]
    }

    /// Все изображения, выбранные для истории (для делегата StoryViewController).
    func allImageDatas() -> [Data] {
        state.items
    }

    /// Обработка нажатия "Добавить изображения".
    func didTapAddImages() {
        let remaining = max(maxItems - state.itemsCount, 0)
        guard remaining > 0 else { return }
        onRequestImagePicker?(remaining)
    }

    /// Контроллер вернул набор Data изображений (из камеры или пикера).
    func didPick(imageDatas: [Data]) {
        guard !imageDatas.isEmpty else { return }

        // Отбросить лишние, если превысили лимит
        let spaceLeft = maxItems - state.itemsCount
        guard spaceLeft > 0 else { return }

        let toAdd = Array(imageDatas.prefix(spaceLeft))
        state.items.append(contentsOf: toAdd)

        // Если до этого ничего не было, текущий индекс поставить в начало
        if state.itemsCount == toAdd.count {
            state.currentIndex = 0
        }

        emitState()
        emitImages()
        startTimerForCurrentItemIfNeeded()
    }

    /// Удаление текущего слайда.
    func didTapDeleteCurrent() {
        guard state.currentIndex < state.itemsCount else { return }

        state.items.remove(at: state.currentIndex)

        if state.currentIndex >= state.itemsCount {
            state.currentIndex = max(state.itemsCount - 1, 0)
        }

        emitState()
        emitImages()

        if state.itemsCount == 0 {
            timer.stop()
        } else {
            startTimerForCurrentItemIfNeeded()
        }
    }

    /// Перейти к следующему слайду.
    func goToNext() {
        guard state.itemsCount > 0 else { return }

        if state.currentIndex < state.itemsCount - 1 {
            state.currentIndex += 1
            emitState()
            emitImages()
            startTimerForCurrentItemIfNeeded()
        } else {
            // На последнем - остановить таймер
            timer.stop()
        }
    }

    /// Пользователь нажал "Опубликовать".
        func didTapPublish() async {
        guard !state.items.isEmpty else { return }

        state.isBusy = true
        emitState()

        do {
            try await performPublish()
            state.isBusy = false
            emitState()
            onCloseAfterPublish?()
        } catch {
            state.isBusy = false
            emitState()
            onError?(error)
        }
    }

    private func emitState() {
        onStateChange?(state)
    }

    private func emitImages() {
        onImagesUpdated?(state.items)
    }

    /// Запускает таймер прогресса для текущего слайда.
    private func startTimerForCurrentItemIfNeeded() {
        timer.stop()
        guard state.itemsCount > 0 else { return }

        timer.start(
            duration: itemDuration,
            tickInterval: 0.03,
            onTick: { [weak self] progress in
                guard let self else { return }
                self.onTickProgress?(progress)
            },
            onCompleted: { [weak self] in
                guard let self else { return }
                self.handleTimerCompleted()
            }
        )
    }

    ///По завершении прогресса либо идём дальше, либо останавливаемся на последнем.
    private func handleTimerCompleted() {
        if state.currentIndex >= state.itemsCount - 1 {
            timer.stop()
        } else {
            goToNext()
        }
    }
    
    /// Сохранение истории в storage.
    private func performPublish() async throws {
        try await storage.save(
            imageDatas: state.items,
            duration: itemDuration,
            for: userId
        )
    }
}
