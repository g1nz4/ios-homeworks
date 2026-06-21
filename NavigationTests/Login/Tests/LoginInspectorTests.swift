import XCTest
@testable import Navigation

/// Тесты доменного слоя авторизации `LoginInspector`.
@MainActor
final class LoginInspectorTests: XCTestCase {
    
    var checkerMock: CheckerServiceMock!
    var userServiceMock: UserServiceMock!
    var authMock: AuthServiceMock!
    var cacheMock: UserCacheStoreMock!
    var networkMock: NetworkStatusServiceMock!
    
    var inspector: LoginInspector!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        checkerMock = CheckerServiceMock()
        userServiceMock = UserServiceMock()
        authMock = AuthServiceMock()
        cacheMock = UserCacheStoreMock()
        networkMock = NetworkStatusServiceMock()
        
        inspector = LoginInspector(
            checkerService: checkerMock,
            userService: userServiceMock,
            authService: authMock,
            userCache: cacheMock,
            networkService: networkMock
        )
    }
    
    override func tearDownWithError() throws {
        inspector = nil
        networkMock = nil
        cacheMock = nil
        authMock = nil
        userServiceMock = nil
        checkerMock = nil
        
        try super.tearDownWithError()
    }
    
    /// Проверяем, что LoginInspector делегирует проверку CheckerService.
    func test_checkCredentials_callsCheckerService() async throws {
        try await inspector.checkCredentials(email: "aaa@bbb.cc", password: "123456")
        XCTAssertTrue(checkerMock.checkCredentialsCalled)
    }
    
    /// Успешная регистрация:  вызывается signUp в checker, создаётся профиль в userService,  пользователь кешируется, возвращаемый User содержит ожидаемый id и email.
    func test_signUp_success_createsProfileAndCachesUser() async throws {
        // given
        let data = SignUpData(
            email: "test@test.ru",
            password: "123456",
            firstName: "Cat",
            lastName: "Developer",
            city: "Moscow",
            phone: "+71234567890",
            birthDate: Date()
        )
        
        checkerMock.signUpError = nil
        authMock.userID = "user-123"
        
        // when
        let user = try await inspector.signUp(data)
        
        // then
        XCTAssertTrue(checkerMock.signUpCalled)
        XCTAssertTrue(userServiceMock.createProfileCalled)
        XCTAssertTrue(cacheMock.saveCalled)
        XCTAssertEqual(user.id, "user-123")
        XCTAssertEqual(user.email, data.email)
    }
    
    /// Если после регистрации у AuthService нет userID, должен прилететь AppError.authGeneric.
    func test_signUp_noUserID_throwsAuthGeneric() async {
        // given
        let data = SignUpData(
        email: "test@test.ru",
        password: "123456",
        firstName: "Cat",
        lastName: "Developer",
        city: "Moscow",
        phone: "+71234567890",
        birthDate: Date()
        )

        authMock.userID = nil
        checkerMock.signUpError = nil

        // when / then
        do {
            _ = try await inspector.signUp(data)
            XCTFail("Expected error, got success")
        } catch {
            guard case AppError.authGeneric = error else {
                return XCTFail("Expected AppError.authGeneric, got \(error)")
            }
        }
    }
    
    /// Успешный вход по телефону:  профиль получаем через userService,  сохраняем в кеш,  выставляем локальную сессию в authService (setLocalSession),  возвращаем корректного пользователя.
    func test_loginByPhone_success_fetchesProfileCachesUser_andSetsLocalSession() async throws {
       // when
       let user = try await inspector.loginByPhone("+71234567890")
       
       // then
       XCTAssertTrue(userServiceMock.fetchProfileByPhoneCalled)
       XCTAssertTrue(cacheMock.saveCalled)
       XCTAssertEqual(user.id, userServiceMock.testUser.id)
       XCTAssertTrue(authMock.setLocalSessionCalled)
       XCTAssertEqual(authMock.setLocalSessionUserID, userServiceMock.testUser.id)
       XCTAssertEqual(authMock.userID, userServiceMock.testUser.id)
    }
    
    /// Если кеш не может сохранить пользователя, получаем AppError.cacheSaveError.
    func test_loginByPhone_cacheSaveError_throwsCacheSaveError() async {
        // given
        cacheMock.saveError = AppError.cacheSaveError
        
        // when / then
        do {
            _ = try await inspector.loginByPhone("+71234567890")
            XCTFail("Expected error, got success")
        } catch {
            guard let appError = error as? AppError,
                  case .cacheSaveError = appError else {
                return XCTFail("Expected AppError.cacheSaveError, got \(error)")
            }
        }
    }
    
    /// userID отсутствует – должен быть AppError.authGeneric.
    func test_loadCurrentUserProfile_noUserID_throwsAuthGeneric() async {
        // given
        authMock.userID = nil
        
        // when / then
        do {
            _ = try await inspector.loadCurrentUserProfile()
            XCTFail("Expected error, got success")
        } catch {
            guard case AppError.authGeneric = error else {
                return XCTFail("Expected AppError.authGeneric, got \(error)")
            }
        }
    }
    
    /// ОНЛАЙН: при наличии сети и успешном запросе профиль берём из сети.
    func test_loadCurrentUserProfile_online_fetchesFromNetwork() async throws {
        // given
        authMock.userID = "user-123"
        networkMock.isConnected = true
        userServiceMock.fetchProfileByIDResult = userServiceMock.testUser
        cacheMock.testLoadedUser = nil
        
        // when
        let user = try await inspector.loadCurrentUserProfile()
        
        // then
        XCTAssertTrue(userServiceMock.fetchProfileByIDCalled)
        XCTAssertEqual(user.id, userServiceMock.testUser.id)
    }
    
    /// ОНЛАЙН: если сеть падает, но в кеше есть пользователь, используем кеш.
    func test_loadCurrentUserProfile_online_networkFails_usesCache() async throws {
        // given
        authMock.userID = "user-123"
        networkMock.isConnected = true
        userServiceMock.fetchProfileByIDError = URLError(.notConnectedToInternet)
        cacheMock.testLoadedUser = userServiceMock.testUser
        
        // when
        let user = try await inspector.loadCurrentUserProfile()
        
        // then
        XCTAssertTrue(userServiceMock.fetchProfileByIDCalled)
        XCTAssertEqual(user.id, userServiceMock.testUser.id)
    }
    
    /// ОНЛАЙН: если сеть падает и кеш пустой, ошибка пробрасывается наружу (но не networkOffline).
    func test_loadCurrentUserProfile_online_networkFails_noCache_throws() async {
        // given
        authMock.userID = "user-123"
        networkMock.isConnected = true
        userServiceMock.fetchProfileByIDError = URLError(.notConnectedToInternet)
        cacheMock.testLoadedUser = nil
        
        // when / then
        do {
            _ = try await inspector.loadCurrentUserProfile()
            XCTFail("Expected error, got success")
        } catch {
            if let appError = error as? AppError,
               case .networkOffline = appError {
                XCTFail("Did not expect AppError.networkOffline here")
            }
        }
    }
    
    /// ОФФЛАЙН: если интернета нет, но в кеше есть пользователь, возвращаем кеш.
    func test_loadCurrentUserProfile_offline_usesCache() async throws {
        // given
        authMock.userID = "user-123"
        networkMock.isConnected = false
        cacheMock.testLoadedUser = userServiceMock.testUser
        
        // when
        let user = try await inspector.loadCurrentUserProfile()
        
        // then
        XCTAssertEqual(user.id, userServiceMock.testUser.id)
        XCTAssertFalse(userServiceMock.fetchProfileByIDCalled)
    }
    
    /// ОФФЛАЙН и кеш пустой – ожидаем AppError.networkOffline.
    func test_loadCurrentUserProfile_offline_noCache_throwsNetworkOffline() async {
        // given
        authMock.userID = "user-123"
        networkMock.isConnected = false
        cacheMock.testLoadedUser = nil
        
        // when / then
        do {
            _ = try await inspector.loadCurrentUserProfile()
            XCTFail("Expected AppError.networkOffline, got success")
        } catch let error as AppError {
            guard case .networkOffline = error else {
                return XCTFail("Expected AppError.networkOffline, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
