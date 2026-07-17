import XCTest
@testable import Navigation

/// Тесты SignUpViewModel – логика формы регистрации и отправки SMS.
@MainActor
final class SignUpViewModelTests: XCTestCase {
    
    var delegateMock: LoginDelegateMock!
    var viewModel: SignUpViewModel!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        delegateMock = LoginDelegateMock()
        viewModel = SignUpViewModel(delegate: delegateMock)
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        delegateMock = nil
        
        try super.tearDownWithError()
    }
    
    /// Невалидный email – ошибка и SMS не отправляется.
    func test_signUp_invalidEmail_setsInvalidEmailError() async {
        viewModel.email = "invalidemail"
        viewModel.password = "123456"
        viewModel.repeatPassword = "123456"
        viewModel.phone = "+71234567890"
        
        await viewModel.signUp()
        
        XCTAssertEqual(viewModel.errorText.value, AppError.invalidEmail.localizedDescription)
        XCTAssertFalse(delegateMock.sendSMSCodeCalled)
    }
    
    /// Слабый пароль – ошибка валидации.
    func test_signUp_weakPassword_setsWeakPasswordError() async {
        viewModel.email = "test@test.ru"
        viewModel.password = "qaz"
        viewModel.repeatPassword = "qaz"
        viewModel.phone = "+71234567890"
        
        await viewModel.signUp()
        
        XCTAssertEqual(viewModel.errorText.value, AppError.weakPassword.localizedDescription)
        XCTAssertFalse(delegateMock.sendSMSCodeCalled)
    }
    
    /// Пароли не совпадают.
    func test_signUp_passwordsDoNotMatch_setsPasswordsDoNotMatchError() async {
        viewModel.email = "test@test.ru"
        viewModel.password = "123456"
        viewModel.repeatPassword = "qwerty"
        viewModel.phone = "+71234567890"
        
        await viewModel.signUp()
        
        XCTAssertEqual(viewModel.errorText.value, AppError.passwordsDoNotMatch.localizedDescription)
        XCTAssertFalse(delegateMock.sendSMSCodeCalled)
    }
    
    /// Невалидный телефон.
    func test_signUp_invalidPhone_setsPhoneInvalidError() async {
        viewModel.email = "test@test.ru"
        viewModel.password = "123456"
        viewModel.repeatPassword = "123456"
        viewModel.phone = "098761"
        
        await viewModel.signUp()
        
        XCTAssertEqual(viewModel.errorText.value, AppError.errorPhoneInvalid.localizedDescription)
        XCTAssertFalse(delegateMock.sendSMSCodeCalled)
    }
    
    /// Успешный сценарий: прошли валидацию, отправили SMS и вызвали onSMSCodeSent.
    func test_signUp_success_sendsSMS_andCallsOnSMSCodeSent() async {
        // given
        viewModel.email = "test@test.ru"
        viewModel.password = "123456"
        viewModel.repeatPassword = "123456"
        viewModel.firstName = "Test"
        viewModel.lastName = "User"
        viewModel.city = "Debug"
        viewModel.phone = "+71234567890"
        viewModel.birthDate = Date()
        
        let exp = expectation(description: "onSMSCodeSent called")
        var sentData: SignUpData?
        var sentVerification: String?
        
        viewModel.onSMSCodeSent = { data, verificationID in
            sentData = data
            sentVerification = verificationID
            exp.fulfill()
        }
        
        // when
        await viewModel.signUp()
        await fulfillment(of: [exp], timeout: 1.0)
        
        // then
        XCTAssertTrue(delegateMock.sendSMSCodeCalled)
        XCTAssertNil(viewModel.errorText.value)
        XCTAssertEqual(viewModel.isLoading.value, false)
        
        XCTAssertNotNil(sentData)
        XCTAssertEqual(sentData?.email, viewModel.email)
        XCTAssertEqual(sentData?.phone, viewModel.phone)
        XCTAssertEqual(sentVerification, delegateMock.testVerificationID)
    }
    
    /// Ошибка при отправке SMS – показываем локализованный текст.
    func test_signUp_sendSMSFailure_setsError() async {
        // given
        viewModel.email = "test@test.ru"
        viewModel.password = "123456"
        viewModel.repeatPassword = "123456"
        viewModel.phone = "+71234567890"
        
        delegateMock.sendSMSCodeError = AppError.otpInvalid
        
        // when
        await viewModel.signUp()
        
        // then
        XCTAssertTrue(delegateMock.sendSMSCodeCalled)
        XCTAssertEqual(viewModel.errorText.value, AppError.otpInvalid.localizedDescription)
    }
}
