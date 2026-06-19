import Foundation

/// Протокол сервиса проверки учётных данных и отправки / подтверждения SMS-кодов.
protocol CheckerServiceProtocol {
   /// Проверка email / пароля через Supabase Auth.
   func checkCredentials(email: String, password: String) async throws
   /// Регистрация по email / паролю.
   func signUp(email: String, password: String) async throws
   /// Отправка SMS-кода на указанный телефон.
   func sendSMSCode(to phone: String) async throws -> String
   /// Проверка SMS-кода.
   func verifySMSCode(verificationID: String, code: String) async throws
}

/// Реализация CheckerServiceProtocol, оборачивает Supabase-сервисы.
final class CheckerService: CheckerServiceProtocol {
    // Сервис аутентификации Supabase (email/пароль).
    private let authService: SupabaseAuthService
    // Сервис одноразовых кодов SMS (OTP) через Supabase.
    private let otpService: SupabaseOTPService
    
    init(
        authService: SupabaseAuthService = SupabaseAuthService.shared,
        otpService: SupabaseOTPService = SupabaseOTPService()
    ) {
        self.authService = authService
        self.otpService = otpService
    }
    
    func checkCredentials(email: String, password: String) async throws {
        // Попытка авторизации
        _ = try await authService.signIn(email: email, password: password)
    }
    
    func signUp(email: String, password: String) async throws {
        // Регистрация нового пользователя в Supabase Auth
        _ = try await authService.signUp(email: email, password: password)
    }
    
    func sendSMSCode(to phone: String) async throws -> String {
        // Отправка SMS-кода. Возвращаемое значение трактуется как verificationID
        try await otpService.sendCode(to: phone)
    }
    
    func verifySMSCode(verificationID: String, code: String) async throws {
        // В verifyCode phone = verificationID
        try await otpService.verifyCode(phone: verificationID, code: code)
    }
}
