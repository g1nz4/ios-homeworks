import Foundation

/// Запись одноразового кода в таблице phone_otp.
struct OTPRecord: Codable {
    let phone: String
    let code: String
    let expiresAt: String
}

/// Сервис для работы с одноразовыми SMS‑кодами через таблицу phone_otp.
final class SupabaseOTPService {
    
    private let client: SupabaseRESTClient
    
    init(client: SupabaseRESTClient) {
        self.client = client
    }
    
    /// Отправка "SMS": создаём запись в phone_otp и печатаем код в консоль.
    func sendCode(to rawPhone: String) async throws -> String {
        // Форматируем телефон до "+7XXXXXXXXXX"
        let (_, plain) = PhoneFormatter.format(rawPhone)
        AppLogger.debug("SEND OTP phone: \(plain)")
        
        // Генерируем случайный 6‑значный код
        let code = String(format: "%06d", Int.random(in: 0..<1_000_000))
        
        // Срок жизни кода — 1 минута
        let expiresDate = Date().addingTimeInterval(1 * 60)
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        let expiresString = iso.string(from: expiresDate)
        
        // DTO для записи в Supabase, записываем уже нормализованный телефон
        let record = OTPRecord(
            phone: plain,
            code: code,
            expiresAt: expiresString
        )
        
        // Supabase insert ожидает массив объектов
        let body = try client.encode([record])
        
        var request = client.makeRESTRequest(
            path: "phone_otp",
            method: "POST",
            body: body
        )
        // upsert по phone, чтобы не плодить записи
        request.addValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        
        // Выполняем запрос
        try await client.performVoid(request)
        
        
        AppLogger.debug("ВАШ КОД ПОДТВЕРЖДЕНИЯ: \(plain) : \(code)")
        
        // возвращаем verificationID — нормализованный телефон
        return plain
    }
    
    /// Проверка кода: читаем phone_otp по номеру телефона и сверяем.
    func verifyCode(phone: String, code: String) async throws {
        let queryItems = [
            URLQueryItem(name: "phone", value: "eq.\(phone)"),           // фильтр по полю phone
            URLQueryItem(name: "select", value: "*"),                    // берём все поля
            URLQueryItem(name: "order", value: "expires_at.desc"),       // сортируем по последней записи
            URLQueryItem(name: "limit", value: "1")                      // нужна только одна
        ]
        
        let request = client.makeRESTRequest(
            path: "phone_otp",
            queryItems: queryItems
        )
        
        let records: [OTPRecord] = try await client.perform(request)
        
        guard let record = records.first else {
            throw AppError.otpNotFound
        }
        
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Сравниваем введённый код с сохранённым
        guard record.code == trimmedCode else {
            throw AppError.otpInvalid
        }
        
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        
        guard let exp = iso.date(from: record.expiresAt) else {
            throw AppError.otpInvalidDate
        }
        
        guard exp > Date() else {
            throw AppError.otpExpired
        }
        
        AppLogger.debug("🎉🎉🎉 OK 🎉🎉🎉")
    }
}
