import Foundation

protocol StoryTimerProtocol {
    func start(
        duration: TimeInterval,
        tickInterval: TimeInterval,
        onTick: @escaping (Double) -> Void,
        onCompleted: @escaping () -> Void
    )

    func stop()
}

/// Реализация таймера для сториз на базе Foundation.Timer. Хранит `startDate`, чтобы вычислять прогресс по времени.  Автоматически останавливает себя при достижении 100% и вызывает onCompleted.
final class StoryTimer: StoryTimerProtocol {

    private var timer: Timer?
    private var startDate: Date?
    private var duration: TimeInterval = 0
    private var onTick: ((Double) -> Void)?
    private var onCompleted: (() -> Void)?

    func start(
        duration: TimeInterval,
        tickInterval: TimeInterval,
        onTick: @escaping (Double) -> Void,
        onCompleted: @escaping () -> Void
    ) {
        stop()

        self.duration = duration
        self.onTick = onTick
        self.onCompleted = onCompleted
        self.startDate = Date()

        let timer = Timer.scheduledTimer(
            timeInterval: tickInterval,
            target: self,
            selector: #selector(handleTick),
            userInfo: nil,
            repeats: true
        )
        // Используется .common, чтобы таймер не стопорился во время скролла/жестов
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        startDate = nil
        onTick = nil
        onCompleted = nil
    }

    /// Обработчик каждого тика.
    @objc private func handleTick() {
        guard let startDate else { return }

        let elapsed = Date().timeIntervalSince(startDate)
        // Прогресс всегда в диапазоне [0, 1]
        let progress = min(max(elapsed / duration, 0), 1)

        onTick?(progress)

        if progress >= 1.0 {
            // Сохранить ссылку на completion, т.к. stop() его обнуляет
            let completion = onCompleted
            stop()
            completion?()
        }
    }
}
