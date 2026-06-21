import Foundation

/// ViewModel для сценария авторизации по телефону.  Инкапсулирует отправку и проверку кода, таймер и режимы login / signUp.
@MainActor
final class PhoneLoginViewModel {
    
    /// Экранное состояние: ввод телефона или ввод кода.
    enum State {
        case enterPhone
        case enterCode
    }
    /// Режим работы:  вход или регистрация.
    enum Mode {
        case login
        case signUp(SignUpData)
    }
    
    private weak var delegate: LoginDelegateProtocol?
    
    /// Текущее состояние экрана (номер / код).
    let state = Observable<State>(.enterPhone)
    
    /// Номер телефона в формате +7...
    var phone: String = ""
    /// Введённый код (OTP).
    var code: String = ""
    
    /// plain‑номер должен быть в формате +7XXXXXXXXXX (12 символов)
    var isPhoneValid: Bool {
        phone.hasPrefix("+7") && phone.count == 12
    }
    
    let isLoading = Observable<Bool>(false)
    let errorText = Observable<String?>(nil)
    
    /// Оставшееся время таймера (в секундах). nil — таймер не запущен.
    let secondsLeft = Observable<Int?>(nil)
    /// Можно ли запросить код повторно (после истечения таймера).
    let canResend = Observable<Bool>(false)
    /// Колбэк успешной авторизации / регистрации.
    var onSuccess: ((User) -> Void)?
    
    private var verificationID: String?
    private var timer: Timer?
    /// Длительность таймера до повторного запроса кода.
    private let totalSeconds = 60
    private let mode: Mode
    
    init(
        delegate: LoginDelegateProtocol,
        mode: Mode = .login,
        initialPhone: String? = nil,
        initialVerificationID: String? = nil,
        initialState: State = .enterPhone
    ) {
        self.delegate = delegate
        self.mode = mode
        
        if let initialPhone {
            self.phone = initialPhone
        }
        
        if let initialVerificationID {
            self.verificationID = initialVerificationID
        }
        state.value = initialState
        
        if initialState == .enterCode {
            startTimer()
        }
    }
    
    /// Вызывается после ввода полного кода (6 цифр).
    /// Проверяет код через Supabase и либо логинит, либо регистрирует пользователя. В случае неуспеха показывает ошибку и возвращает экран к вводу номера телефона.
    func verify() async {
        guard  let delegate = self.delegate else { return }
        
        let code = self.code.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let id = self.verificationID else {
            self.errorText.value = AppError.errorOtpNoVerificationID.localizedDescription
            return
        }
        // Остановить таймер, как только начали проверку кода
        self.timer?.invalidate()
        self.timer = nil
        self.secondsLeft.value = nil
        self.canResend.value = false
        self.isLoading.value = true
        self.errorText.value = nil
        defer { self.isLoading.value = false }
        
        do {
            AppLogger.debug("VERIFY phone: \( id), code: \(code)")
            try await delegate.verifySMSCode(verificationID: id, code: code)
            AppLogger.debug("verifySMSCode OK")
            
            let user: User
            switch self.mode {
            case .login:
                user = try await delegate.loginByPhone(self.phone)
            case .signUp(let data):
                user = try await delegate.signUp(data)
            }
            
            self.onSuccess?(user)
        } catch {
            // неверный/просроченный код
            self.errorText.value = AppError.errorOtpWrongCodeRetry.localizedDescription
            
            // Сброс verificationID и таймера
            self.verificationID = nil
            self.timer?.invalidate()
            self.timer = nil
            self.secondsLeft.value = nil
            self.canResend.value = false
            
            // Вернуться на экран ввода номера
            self.state.value = .enterPhone
            return
        }
    }
    
    /// Отправка SMS‑кода на номер телефона.
    func sendCode() async  {
        guard let delegate = self.delegate else { return }
        
        guard isPhoneValid else {
            errorText.value = AppError.errorPhoneInvalid.localizedDescription
            return
        }
        
        let number = self.phone
        
        isLoading.value = true
        errorText.value = nil
        defer { isLoading.value = false }
        
        do {
            // В Supabase verificationID = номер телефона
            let id = try await delegate.sendSMSCode(to: number)
            self.verificationID = id
            state.value = .enterCode
            startTimer()
        } catch {
            errorText.value = error.localizedDescription
        }
    }

    /// Запускает/перезапускает таймер до повторной отправки кода.
    func startTimer() {
        timer?.invalidate()
        secondsLeft.value = totalSeconds
        canResend.value = false
        
        self.timer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(Self.handleTimerTick),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(self.timer!, forMode: .common)
    }
    
    /// Повторная отправка кода после окончания таймера.
    func resendCode() async {
        guard canResend.value else { return }
        
        guard let delegate = self.delegate else { return }
        
        guard isPhoneValid else {
            errorText.value = AppError.errorPhoneInvalid.localizedDescription
            return
        }
        
        let number = self.phone
        
        isLoading.value = true
        errorText.value = nil
        defer { isLoading.value = false }
        
        do {
            let id = try await delegate.sendSMSCode(to: number)
            self.verificationID = id
            startTimer()
        } catch {
            errorText.value = error.localizedDescription
        }
    }
    
    /// Тик таймера: уменьшаем счётчик и разрешаем resend, когда он дойдёт до нуля.
    @objc private func handleTimerTick() {
        let current = secondsLeft.value ?? 0
        let newValue = current - 1
        
        if newValue <= 0 {
            secondsLeft.value = 0
            canResend.value = true
            timer?.invalidate()
            timer = nil
        } else {
            secondsLeft.value = newValue
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}
