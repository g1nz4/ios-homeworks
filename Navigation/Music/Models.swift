import Foundation

/// Снимок состояния плеера в текущий момент.
struct PlayerState {
    let currentTrack: Track?
    let isPlaying: Bool
    let progress: Double //0..1
    let repeatMode: RepeatMode
}

/// Модель аудио‑трека.
struct Track: Equatable, Hashable {
    let id: UUID
    let fileName: String
    let title: String
    let artist: String
    let albumTitle: String?
    let coverFileName: String?
}


