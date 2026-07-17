import XCTest
@testable import Navigation

/// Тесты PhoneLoginViewModel – сценарий логина по телефону и коду.
@MainActor
final class PhoneLoginViewModelTests: XCTestCase {
    
    var delegateMock: LoginDelegateMock!
    var viewModel: PhoneLoginViewModel!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        delegateMock = LoginDelegateMock()
        viewModel = PhoneLoginViewModel(
            delegate: delegateMock,
            mode: .login
        )
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        delegateMock = nil
        
        try super.tearDownWithError()
    }
    
    /// Невалидный номер при отправке кода – ошибка и делегат не вызывается.
    func test_sendCode_invalidPhone_setsError_andDoesNotCallDelegate() async {
        viewModel.phone = "12345"
        
        await viewModel.sendCode()
        
        XCTAssertFalse(delegateMock.sendSMSCodeCalled)
        XCTAssertEqual(viewModel.errorText.value, AppError.errorPhoneInvalid.localizedDescription)
    }
    
    /// Успешная отправка кода – состояние меняется на .enterCode.
    func test_sendCode_success_movesToEnterCode_andStartsLoadingCycle() async {
        viewModel.phone = "+71234567890"
        
        await viewModel.sendCode()
        
        XCTAssertTrue(delegateMock.sendSMSCodeCalled)
        XCTAssertEqual(viewModel.state.value, .enterCode)
        XCTAssertNil(viewModel.errorText.value)
        XCTAssertEqual(viewModel.isLoading.value, false)
    }
    
    /// Успешная проверка кода в режиме login – вызывается loginByPhone и onSuccess.
    func test_verify_success_inLoginMode_callsVerifyAndLoginByPhone_andOnSuccess() async {
        // given
        viewModel.phone = "+71234567890"
        viewModel.code = "123456"
        
        await viewModel.sendCode()
        XCTAssertTrue(delegateMock.sendSMSCodeCalled)
        
        let exp = expectation(description: "onSuccess called")
        var receivedUser: User?
        viewModel.onSuccess = { user in
            receivedUser = user
            exp.fulfill()
        }
        
        // when
        await viewModel.verify()
        await fulfillment(of: [exp], timeout: 1.0)
        
        // then
        XCTAssertTrue(delegateMock.verifySMSCodeCalled)
        XCTAssertTrue(delegateMock.loginByPhoneCalled)
        XCTAssertNotNil(receivedUser)
        XCTAssertEqual(receivedUser?.id, delegateMock.testUser.id)
        XCTAssertNil(viewModel.errorText.value)
        XCTAssertEqual(viewModel.isLoading.value, false)
    }
    
    /// Неверный код – показываем сообщение и возвращаемся на экран ввода телефона.
    func test_verify_wrongCode_setsError_andReturnsToEnterPhone() async {
        viewModel.phone = "+71234567890"
        viewModel.code = "666666"
        
        await viewModel.sendCode()
        delegateMock.verifySMSCodeError = AppError.errorOtpWrongCodeRetry
        
        await viewModel.verify()
        
        XCTAssertTrue(delegateMock.verifySMSCodeCalled)
        XCTAssertEqual(viewModel.errorText.value, AppError.errorOtpWrongCodeRetry.localizedDescription)
        XCTAssertEqual(viewModel.state.value, .enterPhone)
    }
    
    /// В режиме signUp после успешной проверки кода вызывается signUp у делегата.
    func test_verify_success_inSignUpMode_callsSignUp_andOnSuccess() async {
        let signUpData = SignUpData(
                email: "test@test.ru",
                password: "123456",
                firstName: "Cat",
                lastName: "Developer",
                city: "Moscow",
                phone: "+71234567890",
                birthDate: Date()
            )
        
        // новая VM в режиме регистрации
        viewModel = PhoneLoginViewModel(
            delegate: delegateMock,
            mode: .signUp(signUpData)
        )
        
        viewModel.phone = signUpData.phone
        viewModel.code = "123456"
        
        // сначала отправляем код
        await viewModel.sendCode()
        XCTAssertTrue(delegateMock.sendSMSCodeCalled)
        
        let exp = expectation(description: "onSuccess called")
        var receivedUser: User?
        viewModel.onSuccess = { user in
            receivedUser = user
            exp.fulfill()
        }
        
        await viewModel.verify()
        await fulfillment(of: [exp], timeout: 1.0)
        
        XCTAssertTrue(delegateMock.verifySMSCodeCalled)
        XCTAssertTrue(delegateMock.signUpCalled)
        XCTAssertNotNil(receivedUser)
        XCTAssertEqual(receivedUser?.id, delegateMock.testUser.id)
    }
    
    /// resendCode должен работать только когда canResend == true и телефон валиден.
    func test_resendCode_onlyWhenCanResendTrue_andPhoneValid() async {
        viewModel.phone = "+71234567890"
        viewModel.canResend.value = false
        
        await viewModel.resendCode()
        XCTAssertFalse(delegateMock.sendSMSCodeCalled)
        
        viewModel.canResend.value = true
        
        await viewModel.resendCode()
        XCTAssertTrue(delegateMock.sendSMSCodeCalled)
    }
}
