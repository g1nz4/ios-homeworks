import XCTest
@testable import Navigation

/// Мок кеша пользователя (CoreData).
final class UserCacheStoreMock: UserCacheStoreProtocol {
    
    var storage: [String: User] = [:]
    
    var saveCalled = false
    var saveError: Error?
    
    var testLoadedUser: User?
    
    func save(_ user: User) throws {
        saveCalled = true
        if let error = saveError { throw error }
        storage[user.id] = user
    }
    
    func load(userID: String) throws -> User? {
        if let stub = testLoadedUser {
            return stub
        }
        
        return storage[userID]
    }
}
