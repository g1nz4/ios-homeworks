import UIKit

struct Photo {
    let id: Int
    let imageName: String
}

extension Photo {
    static func allPhotos() -> [Photo] {
        (1...20).map { Photo(id: $0, imageName: "supernaturalNewYear_\($0)")}
    }
    
    static func returnFirstFew(count: Int) -> [Photo] {
        let array = Array(allPhotos().prefix(count))
        return array
    }
}
