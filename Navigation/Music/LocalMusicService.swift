import Foundation
import AVFoundation

/// Сервис воспроизведения музыки.
///
/// Отвечает за:
/// 1. загрузку треков,
/// 2.  управление плеером (play/pause/stop/seek/next/prev),
/// 3.  оповещение об изменении состояния плеера.
protocol MusicPlayerService: AnyObject {

    /// Текущее состояние плеера (текущий трек, воспроизведение, прогресс, режим повтора).
    var state: PlayerState { get }
    /// Колбэк, вызываемый при любом изменении состояния плеера.
    var onStateChanged: ((PlayerState) -> Void)? { get set }
    /// Возвращает список всех доступных треков.
    func loadAllTracks() async throws -> [Track]
    /// Начать воспроизведение конкретного трека.
    func play(track: Track) async throws
    /// Поставить на паузу или продолжить воспроизведение.
    func togglePlayPause() async
    /// Остановить воспроизведение и сбросить позицию в начало трека.
    func stop() async
    /// Перемотка к позиции в треке по доле от 0.0 до 1.0.
    func seek(to fraction: Double) async
    /// Переключиться к следующему треку.
    func next() async
    /// Переключиться к предыдущему треку.
    func previous() async
    /// Переключить режим повтора (none → all → one → none).
    func toggleRepeatMode() async
}

/// Доменные ошибки музыкального сервиса.
enum MusicServiceError: Error {
    /// Файл трека не найден в Bundle.
    case fileNotFound
    /// Не удалось инициализировать AVAudioPlayer.
    case playerInitFailed
}

/// Реализация музыкального сервиса, работающая с локальными файлами в Bundle.
final class LocalMusicService: NSObject, MusicPlayerService {

    /// Плеер Apple для воспроизведения аудио.
    private var player: AVAudioPlayer?

    /// Индекс текущего трека в массиве `tracks`.
    private var currentIndex: Int?

    /// Таймер для "живого" обновления прогресса воспроизведения.
    /// Используется  CADisplayLink, чтобы регулярно дергать селектор.
    private var progressTimer: CADisplayLink?

    /// Время последней отправки прогресса (для ограничения частоты обновлений).
    private var lastProgressEmitTime: CFTimeInterval = 0

    /// Локально доступные треки.  Здесь используются заранее известные файлы из Bundle.
    private(set) var tracks: [Track] = [
        Track(
            id: UUID(),
            fileName: "Nirvana_-_Smells_Like_Teen_Spirit",
            title: "Smells Like Teen Spirit",
            artist: "Nirvana",
            albumTitle: "Nevermind",
            coverFileName: "https://cdn.promodj.com/afs/d435357637cce8ce9d8a5c0f8ffec1b512%3Aresize%3A2000x2000%3Asame%3Ab97c2c"
        ),
        Track(
            id: UUID(),
            fileName: "Bob_Seger_The_Silver_Bullet_Band_-_The_Famous_Final_Scene",
            title: "The Famous Final Scene",
            artist: "Bob Seger & The Silver Bullet Band",
            albumTitle: "Stranger in Town",
            coverFileName: "https://static.insales-cdn.com/images/products/1/297/900186409/3550569291.jpg"
        ),
        Track(
            id: UUID(),
            fileName: "Annisokay - Get Your Shit Together",
            title: "Get Your Shit Together",
            artist: "Annisokay",
            albumTitle: nil,
            coverFileName: "https://cdn-image.zvuk.com/pic?hash=4e3f333b-9e26-483b-a56b-c1609bbb7e66&id=41918066&size=large&type=release"
        ),
        Track(
            id: UUID(),
            fileName: "AntXres_LVTE_BLOOMER_-_Reach_The_Spot",
            title: "Reach The Spot",
            artist: "AntXres, LVTE, BLOOMER",
            albumTitle: nil,
            coverFileName: "https://avatars.yandex.net/get-music-content/9784575/36b52a66.a.25851832-1/m1000x1000"
        ),
        Track(
            id: UUID(),
            fileName: "LAST_RIDE_-_I_Am_That_Storm_(MP3.tm)",
            title: "I Am That Storm",
            artist: "LAST RIDE",
            albumTitle: nil,
            coverFileName: "https://avatars.yandex.net/get-music-content/15682289/5efe00e5.a.41747374-1/m1000x1000"
        )
    ]

    /// Текущий режим повтора.
    private(set) var repeatMode: RepeatMode = .none

    /// Колбэк, вызываемый при любом изменении состояния плеера.
    var onStateChanged: ((PlayerState) -> Void)?

    /// "Снимок" текущего состояния плеера.
    /// Собирается из приватных свойств: текущего трека, флага `isPlaying`,  прогресса и режима повтора.
    var state: PlayerState {
        PlayerState(
            currentTrack: currentTrack,
            isPlaying: isPlaying,
            progress: currentProgress,
            repeatMode: repeatMode
        )
    }

    /// Доступ к текущему треку по индексу.
    private var currentTrack: Track? {
        guard let index = currentIndex, tracks.indices.contains(index) else { return nil }
        return tracks[index]
    }

    /// Флаг, играет ли сейчас плеер.
    private var isPlaying: Bool {
        player?.isPlaying ?? false
    }

    /// Текущий прогресс трека в диапазоне [0, 1].
    private var currentProgress: Double {
        guard let player = player, player.duration > 0 else { return 0 }
        return player.currentTime / player.duration
    }

    func loadAllTracks() async throws -> [Track] {
        // В реальном приложении здесь могла бы быть загрузка с диска/сети/сервера
        // Но в данном случае треки захардкоржены в массиве
        tracks
    }

    func play(track: Track) async throws {
        // Поиск индекса трека в массиве и передача в приватный метод
        guard let index = tracks.firstIndex(of: track) else { return }
        try await playAtIndex(index)
    }

    func togglePlayPause() async {
        // Все операции с AVAudioPlayer выполняются на главном потоке
        await MainActor.run { [weak self] in
            guard let self, let player = player else { return }

            if player.isPlaying {
                // Если воспроизводится — поставить на паузу
                player.pause()
                self.stopProgressTimer()
            } else {
                // Если на паузе — продолжить воспроизведение
                player.play()
                self.startProgressTimer()
            }

            // После любого изменения воспроизведения уведомить подписчиков
            self.emitState()
        }
    }

    func stop() async {
        await MainActor.run { [weak self] in
            guard let self, let player = player else { return }

            // Полная остановка: AVAudioPlayer переход в состояние "остановлен"
            player.stop()

            // Сброс текущей позиции трека в начало
            player.currentTime = 0

            // Выбранный трек остаётся текущим, но не проигрывается
            self.stopProgressTimer()
            self.emitState()
        }
    }

    func seek(to fraction: Double) async {
        await MainActor.run { [weak self] in
            guard let self, let player = player, player.duration > 0 else { return }

            // Ограничить fraction диапазоном [0, 1]
            let clamped = max(0, min(fraction, 1))

            // Перевод доли в секунды трека и устанавка времени проигрывания
            player.currentTime = clamped * player.duration

            // Если трек в данный момент воспроизводится, продолжить с новой позиции
            if player.isPlaying {
                player.play()
            }

            // После перемотки тоже оповестить UI о новом прогрессе
            self.emitState()
        }
    }

    func next() async {
        // Если текущий трек не выбран — ничего не делаеть
        guard let currentIndex else { return }

        let nextIndex = currentIndex + 1

        // Если есть следующий трек в массиве — просто воспроизвести его
        if tracks.indices.contains(nextIndex) {
            try? await playAtIndex(nextIndex)
            return
        }

        // Если в конце конца плейлиста:
        //  при режиме повтора .all переход к первому треку,
        //  при .none / .one — ничего не делать
        if repeatMode == .all, !tracks.isEmpty {
            try? await playAtIndex(0)
        }
    }

    func previous() async {
        // Аналогично next, но в обратную сторону
        guard let currentIndex else { return }

        let prevIndex = currentIndex - 1
        guard tracks.indices.contains(prevIndex) else { return }

        try? await playAtIndex(prevIndex)
    }

    func toggleRepeatMode() async {
        // Циклично переключаем режимы повтора
        switch repeatMode {
        case .none:
            repeatMode = .all
        case .all:
            repeatMode = .one
        case .one:
            repeatMode = .none
        }

        emitState()
    }

    /// Воспроизвести трек по индексу в массиве `tracks`.
    private func playAtIndex(_ index: Int) async throws {
        try await MainActor.run { [weak self] in
            guard let self else { return }

            let track = tracks[index]

            // Поиск файла в Bundle по имени `fileName` и расширению mp3.
            guard let url = Bundle.main.url(forResource: track.fileName, withExtension: "mp3") else {
                throw MusicServiceError.fileNotFound
            }

            do {
                // Создать новый экземпляр AVAudioPlayer для выбранного трека
                let player = try AVAudioPlayer(contentsOf: url)

                // Сохранить плеер, чтобы он не был освобождён
                self.player = player

                // Подписка на события делегата
                player.delegate = self

                //Подготовка плеера к проигрыванию и запуск
                player.prepareToPlay()
                player.play()

                // Обновить текущий индекс трека
                self.currentIndex = index

                // Запуск таймера прогресса для обновления UI
                self.startProgressTimer()

                // Оповестить подписчиков о новом состоянии
                self.emitState()
            } catch {
                // При любой ошибке инициализации — доменная ошибка сервиса
                throw MusicServiceError.playerInitFailed
            }
        }
    }

    /// Вызывает колбэк `onStateChanged` с текущим состоянием плеера.
    private func emitState() {
        onStateChanged?(state)
    }

    /// Запускает таймер, который раз в небольшой интервал обновляет прогресс.
    private func startProgressTimer() {
        // Если таймер уже запущен — второй раз не запускать
        guard progressTimer == nil else { return }

        // Сохранить момент времени, чтобы ограничить частоту срабатываний
        lastProgressEmitTime = CACurrentMediaTime()

        // CADisplayLink вызывает селектор каждый кадр экрана.
        // Внутри селектора ограничить частоту
        let displayLink = CADisplayLink(target: self, selector: #selector(handleProgressTick(_:)))
        displayLink.add(to: .main, forMode: .common)
        progressTimer = displayLink
    }

    /// Останавливает и уничтожает таймер прогресса.
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    /// Обработчик тиков таймера прогресса.
    @objc private func handleProgressTick(_ displayLink: CADisplayLink) {
        // Если трек перестал играть (пауза/стоп/конец) — остановить таймер
        guard isPlaying else {
            stopProgressTimer()
            return
        }

        let now = CACurrentMediaTime()

        // Отправить обновление прогресса но не чаще, чем раз в 0.1 секунды
        guard now - lastProgressEmitTime >= 0.1 else { return }
        lastProgressEmitTime = now

        emitState()
    }
}

// MARK: - AVAudioPlayerDelegate

extension LocalMusicService: AVAudioPlayerDelegate {

    /// Делегат AVAudioPlayer, вызывается, когда трек доиграл до конца.
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        switch repeatMode {
        case .none:
            // В режиме .none фикс, что трек закончился:
            // - AVAudioPlayer сам переходит в состояние "остановлен"
            // - Остановить таймер прогресса и передать новое состояние
            Task { [weak self] in
                guard let self else { return }
                self.stopProgressTimer()
                self.emitState()
            }

        case .one:
            // В режиме .one повтор того же трека
            if let index = currentIndex {
                Task { [weak self] in
                    try? await self?.playAtIndex(index)
                }
            }

        case .all:
            // В режиме .all  перейти к следующему треку, либо к первому, если дошли до конца плейлиста
            Task { [weak self] in
                guard let self else { return }
                guard let index = self.currentIndex else { return }

                let nextIndex = index + 1

                if self.tracks.indices.contains(nextIndex) {
                    // Если следующий индекс существует — играть его
                    try? await self.playAtIndex(nextIndex)
                } else if !self.tracks.isEmpty {
                    // Если дошли до конца плейлиста — начать с первого трека
                    try? await self.playAtIndex(0)
                }
            }
        }
    }
}
