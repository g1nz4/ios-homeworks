import XCTest
@testable import Navigation

/// Мок реализации AuthServiceProtocol.
/// Используется в тестах LoginInspector, чтобы: отслеживать, был ли вызван signIn / signUp.
final class AuthServiceMock: AuthServiceProtocol {
    
    var userID: String?
 
    var signInCalled = false
    var signUpCalled = false
    var setLocalSessionCalled = false
    var setLocalSessionUserID: String?
    
    var signInResult: SupabaseAuthUser?
    var signUpResult: SupabaseAuthUser?
    
    var signInError: Error?
    var signUpError: Error?
    
    func logout() async throws {
        userID = nil
    }
    
    func signIn(email: String, password: String) async throws -> SupabaseAuthUser {
        signInCalled = true
        if let error = signInError { throw error }
        guard let result = signInResult else {
            return SupabaseAuthUser(id: "mock-id", email: email)
        }
        
        return result
    }
    
    func signUp(email: String, password: String) async throws -> SupabaseAuthUser {
        signUpCalled = true
        if let error = signUpError { throw error }
        guard let result = signUpResult else {
            return SupabaseAuthUser(id: "mock-id", email: email)
        }
        
        return result
    }
    
    func setLocalSession(userID: String) {
        setLocalSessionCalled = true
        setLocalSessionUserID = userID
        self.userID = userID
    }
}
