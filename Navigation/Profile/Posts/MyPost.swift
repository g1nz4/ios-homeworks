import UIKit

struct MyPost {
    let id: String
    let authorId: String
    var author: String
    var image: Data?
    var description: String
    var likes: Int
    var views: Int
    var isExpanded: Bool
    var isLiked: Bool
    var isFavorite: Bool = false
    let createdAt: Date
    var authorAvatarPath: String?
    var imagePath: String?
    var isOnWall: Bool
    
    init(
        id: String,
        authorId: String,
        author: String,
        image: Data? = nil,
        description: String,
        likes: Int,
        views: Int,
        isExpanded: Bool = false,
        isLiked: Bool = false,
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        authorAvatarPath: String? = nil,
        imagePath: String? = nil,
        isOnWall: Bool = false
    ) {
        self.id = id
        self.author = author
        self.authorId = authorId
        self.image = image
        self.description = description
        self.likes = likes
        self.views = views
        self.isExpanded = isExpanded
        self.isLiked = isLiked
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.authorAvatarPath = authorAvatarPath
        self.imagePath = imagePath
        self.isOnWall = isOnWall
    }
}

