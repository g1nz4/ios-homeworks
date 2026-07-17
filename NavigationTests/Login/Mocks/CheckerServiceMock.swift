import XCTest
@testable import Navigation

/// Мок CheckerServiceProtocol – слой базовых проверок логина/регистрации/OTP.
final class CheckerServiceMock: CheckerServiceProtocol {
  
    var checkCredentialsCalled = false
    var signUpCalled = false
    var sendSMSCalled = false
    var verifySMSCalled = false
   
    var signInError: Error?
    var signUpError: Error?
    var sendSMSError: Error?
    var verifySMSError: Error?
    
    func checkCredentials(email: String, password: String) async throws {
        checkCredentialsCalled = true
        if let error = signInError { throw error }
    }
    
    func signUp(email: String, password: String) async throws {
        signUpCalled = true
        if let error = signUpError { throw error }
    }
    
    func sendSMSCode(to phone: String) async throws -> String {
        sendSMSCalled = true
        if let error = sendSMSError { throw error }
       
        return phone
    }
    
    func verifySMSCode(verificationID: String, code: String) async throws {
        verifySMSCalled = true
        if let error = verifySMSError { throw error }
    }
}
