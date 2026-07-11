import Foundation

/// ViewModel для режима ПРОСМОТРА истории.
/// Отвечает за:  загрузку последней истории пользователя из хранилища;  управление переходами по слайдам; запуск/остановку таймера прогресса для текущего слайда;  обновление "живого" текста времени (RelativeDateTimeFormatter).
@MainActor
final class StoryPlayerViewModel {

    /// Полное изменение стейта (список слайдов, индекс, флаг busy и т.п.).
    var onStateChange: ((StoryState) -> Void)?

    /// Для обновления массива картинок.
    var onImagesUpdated: (([Data]) -> Void)?

    /// Прогресс текущего слайда [0, 1] - для прогресс‑баров.
    var onTickProgress: ((Double) -> Void)?

    /// Сигнал "история должна закрыться" .
    var onStoryShouldClose: (() -> Void)?

    /// Сообщения об ошибках (загрузка из storage).
    var onError: ((Error) -> Void)?

    /// Метаданные - дата создания истории.
    var onMetaUpdated: ((Date?) -> Void)?
    
    /// "Живое" время вида "N сек. назад", обновляемое каждую секунду (до 60 сек. далее минуты).
    var onRelativeTimeUpdated: ((String?) -> Void)?

    private var state: StoryState
    private let timer: StoryTimerProtocol           // таймер для прогресса слайдов
    private let itemDuration: TimeInterval          // время показа одного слайда
    private let storage: CDStoryStorageProtocol       // источник историй
    private let userId: String                      // чей сторис показываем

    /// Отдельный таймер только для обновления надписи времени ("N сек. назад").
    private let metaTimer: StoryTimerProtocol

    /// Форматтер относительного времени на русском.
    private let relativeFormatter: RelativeDateTimeFormatter = {
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.locale = Locale(identifier: "ru_RU")
        relativeFormatter.unitsStyle = .short
        return relativeFormatter
    }()

    init(
        itemDuration: TimeInterval = 5.0,
        timer: StoryTimerProtocol,
        storage: CDStoryStorageProtocol,
        userId: String
    ) {
        self.state = StoryState(items: [], currentIndex: 0, isBusy: false, createdAt: nil)
        self.timer = timer
        self.itemDuration = itemDuration
        self.storage = storage
        self.userId = userId
        self.metaTimer = StoryTimer()
    }

    /// Старт загрузки истории.
    func viewDidLoad() {
        Task { [weak self] in
            guard let self else { return }
            await self.loadStories()
        }
    }

    /// Остановка таймеров при уходе с экрана.
    func stopTimer() {
        timer.stop()
        stopMetaTimer()
    }

    /// Загружает последнюю историю пользователя из хранилища.
    private func loadStories() async {
        state.isBusy = true
        emitState()

        do {
            if let loaded = try await storage.loadLastStory(for: userId) {
                // История найдена
                state.items = loaded.items
                state.currentIndex = 0
                state.createdAt = loaded.createdAt
                state.isBusy = false

                emitState()
                emitImages()
                onMetaUpdated?(loaded.createdAt)

                if let createdAt = loaded.createdAt {
                    startMetaTimer(createdAt: createdAt)
                } else {
                    stopMetaTimer()
                    onRelativeTimeUpdated?(nil)
                }

                startTimerForCurrentItemIfNeeded()
            } else {
                // Историй нет - пустой стейт
                state.items = []
                state.currentIndex = 0
                state.createdAt = nil
                state.isBusy = false

                emitState()
                emitImages()
                onMetaUpdated?(nil)
                stopMetaTimer()
                onRelativeTimeUpdated?(nil)
            }
        } catch {
            state.isBusy = false
            emitState()
            stopMetaTimer()
            onRelativeTimeUpdated?(nil)
            onError?(error)
        }
    }

    /// Текущее изображение для показа.
    func currentImageData() -> Data? {
        guard state.currentIndex < state.itemsCount else { return nil }
        return state.items[state.currentIndex]
    }

    /// Перейти к следующему слайду, либо закрыть историю, если слайды закончились.
    func goToNext() {
        guard state.itemsCount > 0 else { return }

        if state.currentIndex < state.itemsCount - 1 {
            state.currentIndex += 1
            emitState()
            emitImages()
            startTimerForCurrentItemIfNeeded()
        } else {
            // На последнем слайде
            stopTimer()
            onStoryShouldClose?()
        }
    }

    private func emitState() {
        onStateChange?(state)
    }

    private func emitImages() {
        onImagesUpdated?(state.items)
    }

    /// Запуск таймера прогресса для текущего слайда.
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

    /// Коллбек по завершении прогресса текущего слайда.
    private func handleTimerCompleted() {
        if state.currentIndex >= state.itemsCount - 1 {
            timer.stop()
            onStoryShouldClose?()
        } else {
            goToNext()
        }
    }

    /// Запускает отдельный таймер, который каждую секунду обновляет надпись "N сек. назад".
    private func startMetaTimer(createdAt: Date) {
        metaTimer.stop()

        // Крутит сутки
        metaTimer.start(
            duration: 24 * 60 * 60,
            tickInterval: 1.0,
            onTick: { [weak self] _ in
                guard let self else { return }
                let text = self.relativeFormatter.localizedString(
                    for: createdAt,
                    relativeTo: Date()
                )
                self.onRelativeTimeUpdated?(text)
            },
            onCompleted: { [weak self] in
                self?.onRelativeTimeUpdated?(nil)
            }
        )

        // Сразу отправить текст, чтобы не ждать секунду до первого тика
        let initialText = relativeFormatter.localizedString(for: createdAt, relativeTo: Date())
        onRelativeTimeUpdated?(initialText)
    }

    /// Останавливает таймер "живого" времени.
    private func stopMetaTimer() {
        metaTimer.stop()
    }
}
