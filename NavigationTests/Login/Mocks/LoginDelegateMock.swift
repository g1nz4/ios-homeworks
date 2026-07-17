import XCTest
@testable import Navigation

/// Мок LoginDelegateProtocol.
/// Его используют в тестах ViewModel'ей, чтобы не дергать настоящий LoginInspector.
final class LoginDelegateMock: LoginDelegateProtocol {
    
    private(set) var checkCredentialsCalled = false
    private(set) var signUpCalled = false
    private(set) var sendSMSCodeCalled = false
    private(set) var verifySMSCodeCalled = false
    private(set) var loadCurrentUserProfileCalled = false
    private(set) var loginByPhoneCalled = false
    
    var checkCredentialsError: Error?
    var signUpError: Error?
    var sendSMSCodeError: Error?
    var verifySMSCodeError: Error?
    var loadCurrentUserProfileError: Error?
    var loginByPhoneError: Error?
    
    var testUser: User = User(
        id: "test-id",
        nickname: "test",
        name: Name(firstName: "Test", lastName: "User"),
        email: "test@test.ru",
        phone: "+70000000000",
        city: "Debug",
        birthDate: Date()
    )
    
    var testVerificationID: String = "test-verification-id"
    
    
    func checkCredentials(email: String, password: String) async throws {
        checkCredentialsCalled = true
        if let error = checkCredentialsError { throw error }
    }
    
    func signUp(_ data: SignUpData) async throws -> User {
        signUpCalled = true
        if let error = signUpError { throw error }
        
        return testUser
    }
    
    func sendSMSCode(to phone: String) async throws -> String {
        sendSMSCodeCalled = true
        if let error = sendSMSCodeError { throw error }
        
        return testVerificationID
    }
    
    func verifySMSCode(verificationID: String, code: String) async throws {
        verifySMSCodeCalled = true
        if let error = verifySMSCodeError { throw error }
    }
    
    func loadCurrentUserProfile() async throws -> User {
        loadCurrentUserProfileCalled = true
        if let error = loadCurrentUserProfileError { throw error }
        
        return testUser
    }
    
    func loginByPhone(_ phone: String) async throws -> User {
        loginByPhoneCalled = true
        if let error = loginByPhoneError { throw error }
        
        return testUser
    }
}
