import Foundation
import StorageService
import CoreData
import UIKit

protocol CoreDataFavoritesPostProtocol {
    func save(post: MyPost) async throws
    func fetchAll() async throws -> [MyPost]
    func delete(post: MyPost) async throws
    func fetch(by author: String) async throws -> [MyPost]
}

final class CoreDataManager: CoreDataFavoritesPostProtocol {
    
    private let stack = CoreDataStack.shared
    
    func fetchAll() async throws -> [MyPost] {
        let context = stack.viewContext
        
        return try await context.perform {
            let request: NSFetchRequest<FavoritePost> = FavoritePost.fetchRequest()
            let result = try context.fetch(request)
            
            return result.compactMap { obj in
                Self.mapFavoritePost(obj)
            }
        }
    }
    
    func save(post: MyPost) async throws {
        let context = stack.newBackgroundContext()
        
        let id = post.id
        let author = post.author
        let image = post.image
        let description = post.description
        let likes = post.likes
        let views = post.views
        
        try await context.perform {
            let request: NSFetchRequest<FavoritePost> = FavoritePost.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            
            let existing = try context.fetch(request)
            if let _ = existing.first { return }
            
            let favorite = FavoritePost(context: context)
            favorite.id = id
            favorite.author = author
            favorite.image = image.pngData()
            favorite.postDescription = description
            favorite.likes = Int64(likes)
            favorite.views = Int64(views)
            
            if context.hasChanges { try context.save() }
        }
    }
    
    func delete(post: MyPost) async throws {
        let context = stack.newBackgroundContext()
        let id = post.id
        
        try await context.perform {
            let request: NSFetchRequest<FavoritePost> = FavoritePost.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            request.fetchLimit = 1
            
            if let object = try context.fetch(request).first {
                context.delete(object)
                if context.hasChanges { try context.save() }
            }
        }
    }
    
    func fetch(by author: String) async throws -> [MyPost] {
        let context = stack.viewContext
        
        return try await context.perform {
            let request: NSFetchRequest<FavoritePost> = FavoritePost.fetchRequest()
            request.predicate = NSPredicate(format: "author CONTAINS[c] %@", author)
            
            let result = try context.fetch(request)
            
            return result.compactMap { obj in
                Self.mapFavoritePost(obj)
            }
        }
    }
    
    static func mapFavoritePost(_ obj: FavoritePost) -> MyPost? {
        guard
            let id = obj.id,
            let author = obj.author,
            let data = obj.image,
            let description = obj.postDescription,
            let image = UIImage(data: data)
        else { return nil }
        
        return MyPost(
            id: id,
            author: author,
            image: image,
            description: description,
            likes: Int(obj.likes),
            views: Int(obj.views)
        )
    }
}


