import Foundation

/// Данные для отображения мини‑плеера.
struct MiniPlayerViewData {
    /// Полный заголовок "Артист — Трек".
    let fullTitle: String
    /// Играет ли сейчас трек.
    let isPlaying: Bool
    /// Находится ли текущий трек в "моих треках".
    let isInMyTracks: Bool
    /// Прогресс проигрывания в диапазоне 0...1.
    let progress: Float
    /// Текущий режим повтора.
    let repeatMode: RepeatMode
}

/// ViewModel мини‑плеера.
///
/// Отвечает за:
/// 1. подписку / обработку состояния плеера
/// 2.  преобразование PlayerState --> MiniPlayerViewData
/// 3. обработку интеракций от View (play/pause, next, prev, seek, repeat)
@MainActor
final class MiniPlayerViewModel {

    /// Единый выход: при каждом изменении данных вью‑модели отдать наружу новый MiniPlayerViewData или nil (если трека нет).
    var onViewDataChanged: ((MiniPlayerViewData?) -> Void)?

    /// Сервис плеера, через который выполняются все действия (play, next и т.п.).
    private let player: MusicPlayerService

    /// Функция, которая по id трека говорит, находится ли он в "моих треках".
    private let isInMyTracksProvider: (UUID?) -> Bool

    init(
        player: MusicPlayerService,
        isInMyTracksProvider: @escaping (UUID?) -> Bool
    ) {
        self.player = player
        self.isInMyTracksProvider = isInMyTracksProvider
    }

    /// Вызывается координатором при каждом изменении состояния плеера.
    func updateFromPlayer(_ state: PlayerState) {
        handleStateChanged(state)
    }

    /// Нажатие по кнопке Play/Pause.
    func playPause() {
        Task { [weak self] in
            await self?.player.togglePlayPause()
        }
    }

    /// Нажатие по кнопке Next.
    func next() {
        Task { [weak self] in
            await self?.player.next()
        }
    }

    /// Нажатие по кнопке Prev.
    func prev() {
        Task { [weak self] in
            await self?.player.previous()
        }
    }

    /// Перемотка по прогресс‑бару.
    func seek(to fraction: Double) {
        Task { [weak self] in
            await self?.player.seek(to: fraction)
        }
    }

    /// Переключение режима повтора.
    func toggleRepeat() {
        Task { [weak self] in
            await self?.player.toggleRepeatMode()
        }
    }

    /// Остановка плеера.
    func stop() {
        Task { [weak self] in
            await self?.player.stop()
        }
    }

    /// Преобразует PlayerState в MiniPlayerViewData и отдает через onViewDataChanged.
    private func handleStateChanged(_ state: PlayerState) {
        guard let track = state.currentTrack else {
            onViewDataChanged?(nil)
            return
        }

        // Собирать читаемый заголовок
        let fullTitle = "\(track.artist) — \(track.title)"

        // Посторить данные для View
        let viewData = MiniPlayerViewData(
            fullTitle: fullTitle,
            isPlaying: state.isPlaying,
            isInMyTracks: isInMyTracksProvider(track.id),
            progress: Float(state.progress),
            repeatMode: state.repeatMode
        )

        onViewDataChanged?(viewData)
    }
}
