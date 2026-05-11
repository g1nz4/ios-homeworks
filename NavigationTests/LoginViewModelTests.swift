import XCTest
@testable import Navigation

final class LoginDelegateMock: LogInViewControllerDelegate {
    
    var checkCredentialsResult: Result<Void, Error> = .success(())
    var signUpResult: Result<Void, Error> = .success(())
    
    func checkCredentials(
        email: String,
        password: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        completion(checkCredentialsResult)
    }
    func signUp(
        email: String,
        password: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        completion(signUpResult)
    }
}

final class LoginViewModelTests: XCTestCase {
    
    func test_login_withEmptyCredentials_emptyCredentialsError() {
        // given
        let delegateMock = LoginDelegateMock()
        let viewModel = LoginViewModel(loginDelegate: delegateMock)
        
        viewModel.email = ""
        viewModel.password = ""
        
        // when
        viewModel.login()
        
        // then
        XCTAssertEqual(viewModel.errorText.value, NavigationError.emptyCredentials.rawValue)
        XCTAssertEqual(viewModel.isLoading.value, false)
    }
    
    func test_login_withInvalidEmail_invalidEmailError() {
        // given
        let delegateMock = LoginDelegateMock()
        let viewModel = LoginViewModel(loginDelegate: delegateMock)
        
        viewModel.email = "abrakadabra mail.ru"
        viewModel.password = "123456"
        
        // when
        viewModel.login()
        
        // then
        XCTAssertEqual(viewModel.errorText.value, NavigationError.invalidEmail.rawValue)
        XCTAssertEqual(viewModel.isLoading.value, false)
    }
    
    func test_login_withWeakPassword_weakPasswordError() {
        // given
        let delegateMock = LoginDelegateMock()
        let viewModel = LoginViewModel(loginDelegate: delegateMock)
        
        viewModel.email = "test@example.com"
        viewModel.password = "123"
        
        // when
        viewModel.login()
        
        // then
        XCTAssertEqual(viewModel.errorText.value, NavigationError.weakPassword.rawValue)
        XCTAssertEqual(viewModel.isLoading.value, false)
    }
    
    func test_login_success_callsOnSuccessAndStopLoading() {
        // given
        let delegateMock = LoginDelegateMock()
        delegateMock.checkCredentialsResult = .success(())
        
        let viewModel = LoginViewModel(loginDelegate: delegateMock)
        viewModel.email = "test@example.com"
        viewModel.password = "123456"
        
        let expectation = expectation(description: "onSuccess called")
        var receivedUser: User?
        
        viewModel.onSuccess = { user in
            receivedUser = user
            expectation.fulfill()
        }
        
        // when
        viewModel.login()
        
        // then
        waitForExpectations(timeout: 1.0)
        XCTAssertNotNil(receivedUser)
        XCTAssertEqual(viewModel.isLoading.value, false)
        XCTAssertNil(viewModel.errorText.value)
    }
    
    func test_login_failure_invalidCredentialsErrorAndStopLoading() {
        // given
        enum TestError: Error { case fail }
        
        let delegateMock = LoginDelegateMock()
        delegateMock.checkCredentialsResult = .failure(TestError.fail)
        
        let viewModel = LoginViewModel(loginDelegate: delegateMock)
        viewModel.email = "test@example.com"
        viewModel.password = "123456"
        
        let expectation = expectation(description: "completion handled")
        
        viewModel.onSuccess = { _ in
            XCTFail("onSuccess should not be called on failure")
        }
        
        // when
        viewModel.login()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        // then
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(viewModel.errorText.value, NavigationError.invalidCredentials.rawValue)
        XCTAssertEqual(viewModel.isLoading.value, false)
    }
}
