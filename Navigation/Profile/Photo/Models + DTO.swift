import Foundation

struct Photo {
    let id: String
    let url: URL
    let albumId: String?
}

enum AlbumType: String {
    case profile
    case saved
    case custom
}

struct PhotoAlbum {
    let id: String
    let title: String
    let type: AlbumType
}

struct PhotoDTO: Codable {
    let id: String
    let userId: String
    let albumId: String?
    let url: String
    let description: String?
    let createdAt: String?
}

extension PhotoDTO {
    func toDomain() -> Photo? {
        guard let url = URL(string: url) else { return nil }
        return Photo(
            id: id,
            url: url,
            albumId: albumId
        )
    }
}

struct PhotoAlbumDTO: Codable {
    let id: String
    let userId: String
    let title: String
    let type: String
    let createdAt: String?
}

extension PhotoAlbumDTO {
    func toDomain() -> PhotoAlbum {
        PhotoAlbum(
            id: id,
            title: title,
            type: AlbumType(rawValue: type) ?? .custom
        )
    }
}



