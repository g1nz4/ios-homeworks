import Foundation
import CoreData

protocol CDPostManagerProtocol {
    /// Upsert: обновляет существующий пост или создаёт новый, сохраняя текущее isFavorite из MyPost
    func save(post: MyPost, ownerId: String) async throws
    
    /// Удаление поста по id
    func delete(postId: String, ownerId: String) async throws
    
    /// Все посты на стене конкретного owner-а
    func fetchAll(ownerId: String) async throws -> [MyPost]
    
    /// Все посты конкретного автора (authorId) на стене owner-а
    func fetch(by authorId: String, ownerId: String) async throws -> [MyPost]
    
    /// Избранное owner-а + поиск по имени автора
    func fetchFavorites(ownerId: String, authorNameContains: String?) async throws -> [MyPost]
    
    /// Смена флага избранного (по id+ownerId)
    func setFavorite(postId: String, ownerId: String, isFavorite: Bool) async throws
    
    /// Массовое обновление имени автора во всех постах с данным authorId
    func updateAuthorName(authorId: String, newName: String) async throws
}

final class CDPostManager: CDPostManagerProtocol {
    
    private let stack = CoreDataStack.shared
    
    func save(post: MyPost, ownerId: String) async throws {
        let context = stack.newBackgroundContext()
        
        let id = post.id
        let author = post.author
        let authorID = post.authorId
        let image = post.image
        let description = post.description
        let likes = post.likes
        let views = post.views
        let isFavorite = post.isFavorite
        let isLiked = post.isLiked
        let isExpanded = post.isExpanded
        let createdAt = post.createdAt
        let authorAvatarPath = post.authorAvatarPath
        let imagePath = post.imagePath
        let isOnWall = post.isOnWall
        
        try await context.perform {
            let request: NSFetchRequest<CDPost> = CDPost.fetchRequest()
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "id == %@", id),
                NSPredicate(format: "ownerID == %@", ownerId)
            ])
            request.fetchLimit = 1
            
            let existing = try context.fetch(request).first
            
            let cdPost: CDPost
            if let existing {
                cdPost = existing
            } else {
                cdPost = CDPost(context: context)
                cdPost.id = id
                cdPost.ownerID = ownerId
                cdPost.createdAt = createdAt
            }
            
            cdPost.author = author
            cdPost.authorID = authorID
            cdPost.image = image
            cdPost.postDescription = description
            cdPost.likes = Int64(likes)
            cdPost.views = Int64(views)
            cdPost.isFavorite = isFavorite
            cdPost.isLiked = isLiked
            cdPost.isExpanded = isExpanded
            cdPost.authorAvatarPath = authorAvatarPath
            cdPost.imagePath = imagePath
            cdPost.isOnWall = isOnWall
            
            if context.hasChanges { try context.save() }
        }
    }
    
    func delete(postId: String, ownerId: String) async throws {
        let context = stack.newBackgroundContext()
        
        try await context.perform {
            let request: NSFetchRequest<CDPost> = CDPost.fetchRequest()
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "id == %@", postId),
                NSPredicate(format: "ownerID == %@", ownerId)
            ])
            request.fetchLimit = 1
            
            if let object = try context.fetch(request).first {
                context.delete(object)
                if context.hasChanges { try context.save() }
            }
        }
    }
    
    
    func fetchAll(ownerId: String) async throws -> [MyPost] {
        let context = stack.newBackgroundContext()
        
        return try await context.perform {
            let request: NSFetchRequest<CDPost> = CDPost.fetchRequest()
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "ownerID == %@", ownerId),
                NSPredicate(format: "isOnWall == YES")
            ])
            request.sortDescriptors = [
                NSSortDescriptor(key: "createdAt", ascending: false)
            ]
            
            let result = try context.fetch(request)
            return result.compactMap { Self.mapPost($0) }
        }
    }
    
    func fetch(by authorId: String, ownerId: String) async throws -> [MyPost] {
        let context = stack.newBackgroundContext()
        
        return try await context.perform {
            let request: NSFetchRequest<CDPost> = CDPost.fetchRequest()
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "ownerID == %@", ownerId),
                NSPredicate(format: "authorID == %@", authorId)
            ])
            request.sortDescriptors = [
                NSSortDescriptor(key: "createdAt", ascending: false)
            ]
            let result = try context.fetch(request)
            return result.compactMap { Self.mapPost($0) }
        }
    }
    
    func fetchFavorites(
        ownerId: String,
        authorNameContains: String?
    ) async throws -> [MyPost] {
        let context = stack.newBackgroundContext()
        
        return try await context.perform {
            var predicates: [NSPredicate] = [
                NSPredicate(format: "ownerID == %@", ownerId),
                NSPredicate(format: "isFavorite == YES")
            ]
            
            if let text = authorNameContains, !text.isEmpty {
                predicates.append(NSPredicate(format: "author CONTAINS[c] %@", text))
            }
            
            let request: NSFetchRequest<CDPost> = CDPost.fetchRequest()
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.sortDescriptors = [
                NSSortDescriptor(key: "createdAt", ascending: false)
            ]
            
            let result = try context.fetch(request)
            return result.compactMap { Self.mapPost($0) }
        }
    }
    
    func setFavorite(postId: String, ownerId: String, isFavorite: Bool) async throws {
        let context = stack.newBackgroundContext()
        
        try await context.perform {
            let request: NSFetchRequest<CDPost> = CDPost.fetchRequest()
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "id == %@", postId),
                NSPredicate(format: "ownerID == %@", ownerId)
            ])
            request.fetchLimit = 1
            
            if let cdPost = try context.fetch(request).first {
                cdPost.isFavorite = isFavorite
                if context.hasChanges { try context.save() }
            }
        }
    }
    
    func updateAuthorName(authorId: String, newName: String) async throws {
        let context = stack.newBackgroundContext()
        
        try await context.perform {
            let request: NSFetchRequest<CDPost> = CDPost.fetchRequest()
            request.predicate = NSPredicate(format: "authorID == %@", authorId)
            
            let posts = try context.fetch(request)
            guard !posts.isEmpty else { return }
            
            posts.forEach { $0.author = newName }
            
            if context.hasChanges {
                try context.save()
            }
        }
    }
    
    static func mapPost(_ obj: CDPost) -> MyPost? {
        guard
            let id = obj.id,
            let author = obj.author,
            let authorID = obj.authorID,
            let description = obj.postDescription,
            let createdAt = obj.createdAt
        else { return nil }

        return MyPost(
            id: id,
            authorId: authorID,
            author: author,
            image: obj.image,
            description: description,
            likes: Int(obj.likes),
            views: Int(obj.views),
            isExpanded: obj.isExpanded,
            isLiked: obj.isLiked,
            isFavorite: obj.isFavorite,
            createdAt: createdAt,
            authorAvatarPath: obj.authorAvatarPath,
            imagePath: obj.imagePath,
            isOnWall: obj.isOnWall
        )
    }
}


