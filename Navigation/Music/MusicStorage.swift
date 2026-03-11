import Foundation

struct Track {
    let fileName: String
    let title: String
}

final class MusicStorage {

    private(set) var tracks: [Track] = [
        Track(
            fileName: "Nirvana_-_Smells_Like_Teen_Spirit",
            title: "Nirvana - Smells Like Teen Spirit"
        ),
        Track(
            fileName: "Bob_Seger_The_Silver_Bullet_Band_-_The_Famous_Final_Scene",
            title: "Bob Seger The Silver Bullet Band - The Famous Final Scene"
        ),
        Track(
            fileName: "Annisokay - Get Your Shit Together",
            title: "Annisokay - Get Your Shit Together"
        ),
        Track(
            fileName: "AntXres_LVTE_BLOOMER_-_Reach_The_Spot",
            title: "AntXres, LVTE, BLOOMER - Reach The Spot"
        ),
        Track(
            fileName: "Essecer_-_Kuklovod",
            title: "Essecer - Кукловод"
        ),
        Track(
            fileName: "TrackError",
            title: "TrackError"
        )
    ]

    var numberOfTracks: Int {
        tracks.count
    }

    func track(at index: Int) -> Track? {
        guard index >= 0, index < tracks.count else { return nil }
        return tracks[index]
    }
}
