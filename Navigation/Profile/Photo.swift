import UIKit

struct Photo {
    let id: Int
    let imageName: String
}

extension Photo {
    static func allPhotos() -> [Photo] {
        [
            Photo(id: 1, imageName: "supernaturalNewYear_1"),
            Photo(id: 2, imageName: "supernaturalNewYear_2"),
            Photo(id: 3, imageName: "supernaturalNewYear_3"),
            Photo(id: 4, imageName: "supernaturalNewYear_4"),
            Photo(id: 5, imageName: "supernaturalNewYear_5"),
            
            Photo(id: 6, imageName: "supernaturalNewYear_6"),
            Photo(id: 7, imageName: "supernaturalNewYear_7"),
            Photo(id: 8, imageName: "supernaturalNewYear_8"),
            Photo(id: 9, imageName: "supernaturalNewYear_9"),
            Photo(id: 10, imageName: "supernaturalNewYear_10"),
            
            Photo(id: 11, imageName: "supernaturalNewYear_11"),
            Photo(id: 12, imageName: "supernaturalNewYear_12"),
            Photo(id: 13, imageName: "supernaturalNewYear_13"),
            Photo(id: 14, imageName: "supernaturalNewYear_14"),
            Photo(id: 15, imageName: "supernaturalNewYear_15"),
            
            Photo(id: 16, imageName: "supernaturalNewYear_16"),
            Photo(id: 17, imageName: "supernaturalNewYear_17"),
            Photo(id: 18, imageName: "supernaturalNewYear_18"),
            Photo(id: 19, imageName: "supernaturalNewYear_19"),
            Photo(id: 20, imageName: "supernaturalNewYear_20")
        ]
    }
    
    static func returnFirstFew(count: Int) -> [Photo] {
        let array = Array(allPhotos().prefix(count))
        return array
    }
}
