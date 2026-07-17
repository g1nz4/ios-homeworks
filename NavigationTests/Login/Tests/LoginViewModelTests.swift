import XCTest
@testable import Navigation

/// Тесты LoginViewModel – сценарий входа по email/паролю.
@MainActor
final class LoginViewModelTests: XCTestCase {
    
    var delegateMock: LoginDelegateMock!
    var viewModel: LoginViewModel!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        delegateMock = LoginDelegateMock()
        viewModel = LoginViewModel(delegate: delegateMock)
    }
    
    override func tearDownWithError() throws {
        delegateMock = nil
        viewModel = nil
        try super.tearDownWithError()
    }
    
    /// Пустые логин/пароль – показываем ошибку и не зовём делегата.
    func test_login_withEmptyCredentials_setsEmptyCredentialsError_andDoesNotCallDelegate() async {
        // given
        viewModel.email = ""
        viewModel.password = ""
        
        // when
        await viewModel.login()
        
        // then
        XCTAssertEqual(viewModel.errorText.value, AppError.invalidCredentials.localizedDescription)
        XCTAssertEqual(viewModel.isLoading.value, false)
        XCTAssertFalse(delegateMock.checkCredentialsCalled)
        XCTAssertFalse(delegateMock.loadCurrentUserProfileCalled)
    }
    
    /// Некорректный формат email.
    func test_login_withInvalidEmail_setsInvalidEmailError_andDoesNotCallDelegate() async {
        // given
        viewModel.email = "abrakadabra mail.ru"
        viewModel.password = "123456"
        
        // when
        await viewModel.login()
        
        // then
        XCTAssertEqual(viewModel.errorText.value, AppError.invalidEmail.localizedDescription)
        XCTAssertEqual(viewModel.isLoading.value, false)
        XCTAssertFalse(delegateMock.checkCredentialsCalled)
        XCTAssertFalse(delegateMock.loadCurrentUserProfileCalled)
    }
    
    /// Слишком короткий пароль.
    func test_login_withWeakPassword_setsWeakPasswordError_andDoesNotCallDelegate() async {
        // given
        viewModel.email = "developer@test.ru"
        viewModel.password = "123"
        
        // when
        await viewModel.login()
        
        // then
        XCTAssertEqual(viewModel.errorText.value, AppError.weakPassword.localizedDescription)
        XCTAssertEqual(viewModel.isLoading.value, false)
        XCTAssertFalse(delegateMock.checkCredentialsCalled)
        XCTAssertFalse(delegateMock.loadCurrentUserProfileCalled)
    }
    
    /// Успешный сценарий: проверка логина, загрузка профиля, вызов onSuccess.
    func test_login_success_callsDelegate_andOnSuccess_andStopsLoading() async {
        // given
        delegateMock.checkCredentialsError = nil
        
        viewModel.email = "developer@test.ru"
        viewModel.password = "qwe123!"
        
        let exp = expectation(description: "onSuccess called")
        var receivedUser: User?
        
        viewModel.onSuccess = { user in
            receivedUser = user
            exp.fulfill()
        }
        
        // when
        await viewModel.login()
        await fulfillment(of: [exp], timeout: 1.0)
        
        // then
        XCTAssertTrue(delegateMock.checkCredentialsCalled)
        XCTAssertTrue(delegateMock.loadCurrentUserProfileCalled)
        
        XCTAssertNotNil(receivedUser)
        XCTAssertEqual(receivedUser?.id, delegateMock.testUser.id)
        
        XCTAssertEqual(viewModel.isLoading.value, false)
        XCTAssertNil(viewModel.errorText.value)
    }
    
    /// Ошибка авторизации.
    func test_login_failure_onCheckCredentials_setsError_andDoesNotLoadProfile() async  {
        // given
        delegateMock.checkCredentialsError = AppError.authWrongCredentials
        
        viewModel.email = "test@example.com"
        viewModel.password = "123456"
        
        // when
        await viewModel.login()
        
        // then
        XCTAssertTrue(delegateMock.checkCredentialsCalled)
        XCTAssertFalse(delegateMock.loadCurrentUserProfileCalled)

        XCTAssertEqual(viewModel.errorText.value, AppError.authWrongCredentials.localizedDescription)
        XCTAssertEqual(viewModel.isLoading.value, false)
    }
    
    /// Ошибка при загрузке профиля после успешной проверки учетных данных.
    func test_login_failure_onLoadCurrentUserProfile_setsError() async {
        // given
        delegateMock.checkCredentialsError = nil
        delegateMock.loadCurrentUserProfileError = AppError.profileNotFound

        viewModel.email = "test@example.com"
        viewModel.password = "123456"
        
        // when
        await viewModel.login()

        // then
        XCTAssertTrue(delegateMock.checkCredentialsCalled)
        XCTAssertTrue(delegateMock.loadCurrentUserProfileCalled)

        XCTAssertEqual(viewModel.errorText.value, AppError.profileNotFound.localizedDescription)
        XCTAssertEqual(viewModel.isLoading.value, false)
    }
}
