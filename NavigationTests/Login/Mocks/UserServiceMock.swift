import XCTest
@testable import Navigation

/// Мок сервиса работы с профилями пользователя в Supabase.
final class UserServiceMock: UserServiceProtocol {
    
    var createProfileCalled = false
    var fetchProfileByIDCalled = false
    var fetchProfileByPhoneCalled = false
    
    var testUser = User(
        id: "test-user-id",
        nickname: "test",
        name: Name(firstName: "Test", lastName: "User"),
        email: "test@test.ru",
        phone: "+70000000000",
        city: "Debug",
        birthDate: nil
    )
    
    var fetchProfileByIDResult: User?
    var fetchProfileByPhoneResult: User?
    
    var fetchProfileByPhoneError: Error?
    var fetchProfileByIDError: Error?
    
    func createProfile(for user: User) async throws {
        createProfileCalled = true
    }
    
    func fetchProfile(userID: String) async throws -> User {
        fetchProfileByIDCalled = true
        if let error = fetchProfileByIDError { throw error }
        if let result = fetchProfileByIDResult { return result }
        
        return testUser
    }
    
    func fetchProfile(phone: String) async throws -> User {
        fetchProfileByPhoneCalled = true
        if let error = fetchProfileByPhoneError { throw error }
        if let result = fetchProfileByPhoneResult { return result }
        
        return testUser
    }
}
