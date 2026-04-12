import Foundation
import StorageService

protocol FavoritesViewModelProtocol {
    var posts: [MyPost] { get }
   
    @MainActor
    func loadFavorites() async throws
    
    func numberOfRows() -> Int
    func post(at index: Int) -> MyPost?
    
    @MainActor
    func remove(at index: Int) async throws
}

final class FavoritesViewModel: FavoritesViewModelProtocol {
    
    private let storage: CoreDataFavoritesPostProtocol
  
    private(set) var posts: [MyPost] = []
    
    init(storage: CoreDataFavoritesPostProtocol = CoreDataManager()) {
        self.storage = storage
    }
    
    @MainActor
    func loadFavorites() async throws {
        posts = try await storage.fetchAll()
    }
    
    func numberOfRows() -> Int {
        posts.count
    }
    
    func post(at index: Int) -> MyPost? {
        guard posts.indices.contains(index) else { return nil }
        return posts[index]
    }
    
    @MainActor
    func remove(at index: Int) async throws {
        guard posts.indices.contains(index) else { return }
        let post = posts[index]
        try await storage.delete(post: post)
        posts.remove(at: index)
    }
}
