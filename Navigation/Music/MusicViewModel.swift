import Foundation

/// Вкладки экрана музыки.
enum MusicTab: Int, CaseIterable {
    case main      // Главная
    case myTracks  // Мои треки

    /// Заголовок вкладки для UI.
    var title: String {
        switch self {
        case .main:
            return NSLocalizedString("music_tab_main", comment: "")
        case .myTracks:
            return NSLocalizedString("music_tab_my_tracks", comment: "")
        }
    }
}

/// View‑модель одного трека для ячейки.
struct MusicTrackItemViewData: Equatable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    let coverFileName: String?
}

/// View‑модель альбома(пока не реализованы).
struct AlbumItemViewData: Equatable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    let coverFileName: String?
}

/// Публичный контракт для ViewModel экрана музыки.  UI работает только с этим протоколом.
@MainActor
protocol MusicViewModelProtocol: AnyObject {
    // Состояние вкладок и списков
    var selectedTab: MusicTab { get }
    var mainTracks: [MusicTrackItemViewData] { get }
    var myTracks:  [MusicTrackItemViewData] { get }

    // Состояние плеера
    var isPlaying: Bool { get }
    var currentTrackId: UUID? { get }
    var playbackProgress: Float { get }

    // Коллбэки обновления UI
    var onUpdate: (() -> Void)? { get set }
    var onPlaybackUpdate: (() -> Void)? { get set }

    // Жизненный цикл
    func viewDidLoad() async
    func refresh() async

    // Взаимодействия UI
    func didSelectTab(_ tab: MusicTab)
    func didSelectTrack(at index: Int) async
    func toggleMyTrack(id: UUID)

    func playPauseTapped() async
    func stopTapped() async
    func nextTrack() async
    func previousTrack() async
    func seek(to fraction: Double) async

    func didTapPlayPauseForTrack(id: UUID) async
}

/// Основная ViewModel для экрана музыки.
/// Отвечает за:
/// 1.  загрузку/хранение треков;
/// 2.  разделение на «Главная» / «Мои»;
/// 3. синхронизацию состояния с плеером;
/// 4. выдачу ViewData для UI.
@MainActor
final class MusicViewModel: MusicViewModelProtocol {

    private(set) var selectedTab: MusicTab = .main

    /// ViewData для вкладки "Главная".
    private(set) var mainTracks: [MusicTrackItemViewData] = []

    /// ViewData для вкладки "Мои треки".
    private(set) var myTracks:  [MusicTrackItemViewData] = []

    /// Текущее состояние воспроизведения.
    private(set) var isPlaying: Bool = false
    private(set) var currentTrackId: UUID?
    private(set) var playbackProgress: Float = 0

    /// Коллбэк для полного обновления UI.
    var onUpdate: (() -> Void)?

    /// Коллбэк для частого обновления прогресса / иконок (без полного reload).
    var onPlaybackUpdate: (() -> Void)?

    /// Сервис плеера (доменная логика воспроизведения).
    private let player: MusicPlayerService

    /// Все доступные треки (доменная модель).
    private var allTracks: [Track] = []

    /// Выбранные пользователем "Мои треки" (доменная модель).
    private var myTracksDomain: [Track] = []


    init(player: MusicPlayerService) {
        self.player = player
    }

    /// Вызывается координатором при каждом изменении состояния плеера.
    func updateFromPlayer(_ state: PlayerState) {
        handlePlayerStateChanged(state)
    }

    /// Первый вызов при появлении экрана.
    func viewDidLoad() async {
        await loadTracks()
    }

    /// Обновление данных по запросу пользователя (pull‑to‑refresh и т.п.).
    func refresh() async {
        await loadTracks()
    }

    /// Переключение вкладки.
    func didSelectTab(_ tab: MusicTab) {
        guard selectedTab != tab else { return }
        selectedTab = tab
        onUpdate?()
    }

    /// Выбор трека по индексу в текущем списке (главная / мои).
    func didSelectTrack(at index: Int) async {
        let list = currentDomainTracks()
        guard index >= 0, index < list.count else { return }
        let track = list[index]

        try? await player.play(track: track)
    }

    /// Добавление/удаление трека из "Моих".
    func toggleMyTrack(id: UUID) {
        guard let track = allTracks.first(where: { $0.id == id }) ??
                myTracksDomain.first(where: { $0.id == id }) else { return }

        if let idx = myTracksDomain.firstIndex(of: track) {
            myTracksDomain.remove(at: idx)
        } else {
            myTracksDomain.append(track)
        }

        rebuildViewData()
    }

    func playPauseTapped() async {
        await player.togglePlayPause()
    }

    func stopTapped() async {
        await player.stop()
    }

    func nextTrack() async {
        await player.next()
    }

    func previousTrack() async {
        await player.previous()
    }

    func seek(to fraction: Double) async {
        await player.seek(to: fraction)
    }

    /// Нажатие play/pause в ячейке конкретного трека.
    func didTapPlayPauseForTrack(id: UUID) async {
        if currentTrackId == id {
            await playPauseTapped()
            return
        }

        let list = currentDomainTracks()
        guard let track = list.first(where: { $0.id == id }) else { return }

        try? await player.play(track: track)
    }

    /// Загрузка всех треков из сервиса плеера.
    private func loadTracks() async {
        do {
            let tracks = try await player.loadAllTracks()
            self.allTracks = tracks
            rebuildViewData()
        } catch {
            AppLogger.error("Failed to load tracks:\(error)")
        }
    }

    /// Пересборка ViewData (`mainTracks`, `myTracks`) из доменной модели.
    private func rebuildViewData() {
        mainTracks = allTracks.map {
            MusicTrackItemViewData(
                id: $0.id,
                title: $0.title,
                subtitle: $0.artist,
                coverFileName: $0.coverFileName
            )
        }

        myTracks = myTracksDomain.map {
            MusicTrackItemViewData(
                id: $0.id,
                title: $0.title,
                subtitle: $0.artist,
                coverFileName: $0.coverFileName
            )
        }

        onUpdate?()
    }

    /// Текущий список доменных треков в зависимости от выбранной вкладки.
    private func currentDomainTracks() -> [Track] {
        switch selectedTab {
        case .main:     return allTracks
        case .myTracks: return myTracksDomain
        }
    }

    /// Обработка нового состояния плеера и решение, когда достаточно частичного обновления, а когда нужен полный reload.
    private func handlePlayerStateChanged(_ state: PlayerState) {
        let oldCurrentTrackId = currentTrackId
        let oldIsPlaying = isPlaying

        isPlaying = state.isPlaying
        playbackProgress = Float(state.progress)
        currentTrackId = state.currentTrack?.id

        // Оповестить для локального обновления ячеек (прогресс, иконки)
        onPlaybackUpdate?()

        let trackChanged = oldCurrentTrackId != currentTrackId
        let playingChanged = oldIsPlaying != isPlaying

        if trackChanged || playingChanged {
            onUpdate?()
        }
    }

    /// Используется мини‑плеером через координатор:  проверка, находится ли трек в списке "Мои треки".
    func isInMyTracks(id: UUID?) -> Bool {
        guard let id else { return false }
        return myTracksDomain.contains { $0.id == id }
    }
}
