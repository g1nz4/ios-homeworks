//import Foundation
//import AVFoundation
//
////protocol MusicViewModelProtocol {
////    var numberOfTracks: Int { get }
////
////    func viewDidLoad()
////    func playPauseTapped()
////    func stopTapped()
////    func selectTrack(at index: Int)
////    func titleForTrack(at index: Int) -> String
////
////    func bindCurrentTrackName(_ listener: @escaping (String) -> Void)
////    func bindIsPlayingChanged(_ listener: @escaping (Bool) -> Void)
////    func bindError(_ listener: @escaping (String) -> Void)
////}
//
//final class MusicViewModel {
//
////    private let storage: MusicStorage
////    private var player: AVAudioPlayer?
////    private var currentTrackIndex: Int = 0
////    
////    private var currentTrackName: ((String) -> Void)?
////    private var isPlayingChanged: ((Bool) -> Void)?
////    private var errorHandler: ((String) -> Void)?
////    
////    init(storage: MusicStorage = MusicStorage()) {
////        self.storage = storage
////    }
////
////    var numberOfTracks: Int {
////        storage.numberOfTracks
////    }
////
////    func titleForTrack(at index: Int) -> String {
////        storage.track(at: index)?.title ?? "Трек \(index + 1)"
////    }
////
////    func viewDidLoad() {
////        loadTrack(index: currentTrackIndex)
////    }
////
////    func playPauseTapped() {
////        guard let player = player else { return }
////
////        if player.isPlaying {
////            player.pause()
////            isPlayingChanged?(false)
////        } else {
////            player.play()
////            isPlayingChanged?(true)
////        }
////    }
////
////    func stopTapped() {
////        guard let player = player else { return }
////        player.stop()
////        player.currentTime = 0
////        isPlayingChanged?(false)
////    }
////
////    func selectTrack(at index: Int) {
////        guard index >= 0, index < storage.numberOfTracks else { return }
////
////        player?.stop()
////        player?.currentTime = 0
////        isPlayingChanged?(false)
////        loadTrack(index: index)
////        player?.play()
////        isPlayingChanged?(true)
////    }
////
////    func bindCurrentTrackName(_ listener: @escaping (String) -> Void) {
////        currentTrackName = listener
////    }
////
////    func bindIsPlayingChanged(_ listener: @escaping (Bool) -> Void) {
////        isPlayingChanged = listener
////    }
////    
////    func bindError(_ listener: @escaping (String) -> Void) {
////        errorHandler = listener
////    }
////    
////    private func handleError(_ error: NavigationError) {
////        errorHandler?(error.rawValue)
////    }
////
////    private func loadTrack(index: Int) {
////        guard let track = storage.track(at: index) else { return }
////
////        let name = track.fileName
////
////        guard let path = Bundle.main.path(forResource: name, ofType: "mp3") else {
////            player = nil
////            handleError(.fileNotFound)
////            return
////        }
////
////        let url = URL(fileURLWithPath: path)
////
////        do {
////            player = try AVAudioPlayer(contentsOf: url)
////            player?.prepareToPlay()
////            currentTrackIndex = index
////            currentTrackName?("\(track.title)")
////        } catch {
////            handleError(.errorAVAudioPlayer)
////        }
////    }
//}
