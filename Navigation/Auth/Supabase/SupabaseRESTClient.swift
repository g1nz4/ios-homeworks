import Foundation

/// Клиент для REST‑запросов в Supabase (rest/v1/…).
final class SupabaseRESTClient {
    /// JSON‑кодировщик для тел запросов.
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        // Даты в запросах кодируются как ISO8601
        encoder.dateEncodingStrategy = .iso8601
        // camelCase -> snake_case для ключей
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
    
    /// JSON‑декодер для ответов Supabase.
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        // Кастомная стратегия разбора дат: сначала ISO8601, потом "yyyy-MM-dd"
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            
            let iso = ISO8601DateFormatter()
            if let date = iso.date(from: string) {
                return date
            }
            
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.timeZone = TimeZone(secondsFromGMT: 0)
            df.dateFormat = "yyyy-MM-dd"
            if let date = df.date(from: string) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Ожидалась строка даты в формате ISO8601 или гггг-ММ-дд, получено: \(string)"
            )
        }
        
        return decoder
    }()
    
    /// Базовый URL Supabase‑проекта.
    let baseURL: URL = SupabaseConfig.baseURL
    
    /// Публичный anon‑ключ Supabase.
    let apiKey: String = SupabaseConfig.key
    
    /// Сервис аутентификации, выдающий access‑token.
    private let authService: AuthServiceProtocol
    
    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }
    
    /// Конструктор REST‑запроса к rest/v1/<path>.
    func makeRESTRequest(
        path: String,
        method: String = "GET",
        queryItems: [URLQueryItem] = [],
        body: Data? = nil
    ) -> URLRequest {
        var url = baseURL
        url.appendPathComponent("rest/v1")
        url.appendPathComponent(path)
        
        if !queryItems.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            components.queryItems = queryItems
            guard let builtURL = components.url else {
                fatalError("Invalid URL components: \(components)")
            }
            // Заменяем '+' в QUERY‑части на %2B, так как URLComponents превращает его в пробел
            var urlString = builtURL.absoluteString
            if let query = components.percentEncodedQuery, query.contains("+") {
                let fixedQuery = query.replacingOccurrences(of: "+", with: "%2B")
                if let range = urlString.range(of: "?\(query)") {
                    urlString.replaceSubrange(range, with: "?\(fixedQuery)")
                }
            }
            url = URL(string: urlString) ?? builtURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        // Базовые заголовки для Supabase REST
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        
        return request
    }
    
    /// Кодирование любого Encodable‑объекта в Data.
    func encode<T: Encodable>(_ value: T) throws -> Data {
        try encoder.encode(value)
    }
    
    /// Декодирование ответа в нужный тип.
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try decoder.decode(type, from: data)
    }
    
    /// Выполнить запрос без ожидания тела ответа (INSERT/UPDATE/DELETE)).
    func performVoid(_ request: URLRequest) async throws {
        var request = request
        await applyAuthHeaders(to: &request)
        try await performVoidInternal(request, retryOnJWTExpired: true)
    }
    
    /// Выполнить запрос и декодировать JSON‑ответ в тип T.
    /// При 401 / JWT expired пробует один раз обновить сессию и повторить запрос.
    func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        var request = request
        await applyAuthHeaders(to: &request)
        return try await performInternal(request, retryOnJWTExpired: true)
    }
    
    /// Устанавливает заголовок `Authorization`.
    /// Если есть валидный access token -->  `Bearer <token>`,  иначе использует публичный anon‑key.
    private func applyAuthHeaders(to request: inout URLRequest) async {
        do {
            if let token = try await authService.getValidAccessToken() {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            }
        } catch {
            AppLogger.error("Failed to obtain valid access token: \(error)")
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
    }

    /// Проверка, что ошибка связана с просроченным JWT (401 + текст "JWT expired").
    private func isJWTExpired(status: Int, body: String) -> Bool {
        status == 401 && body.contains("JWT expired")
    }
    
    /// Внутренняя реализация `performVoid` с возможностью один раз переотправить  запрос, если токен истёк и был успешно обновлён.
    private func performVoidInternal(
        _ request: URLRequest,
        retryOnJWTExpired: Bool
    ) async throws {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let http = response as? HTTPURLResponse,
                  200..<300 ~= http.statusCode else {
                
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
                
                if retryOnJWTExpired && isJWTExpired(status: status, body: bodyString) {
                    AppLogger.debug("JWT expired, trying to refresh session and retry (void)")
                    try await authService.refreshSession()
                    
                    var newRequest = request
                    await applyAuthHeaders(to: &newRequest)
                    try await performVoidInternal(newRequest, retryOnJWTExpired: false)
                    return
                }
                
                AppLogger.error(
                """
                ===== Supabase REST error (void) =====
                Status: \(status)
                Body: \(bodyString)
                ======================================
                """
                )
                throw AppError.supabase(status: status, message: bodyString)
            }
        } catch let error as AppError {
            throw error
        } catch {
            AppLogger.error("URLSession error (void): \(error)")
            throw AppError.network(underlying: error)
        }
    }
    
    /// Внутренняя реализация `perform` с логированием сырого ответа, повторной попыткой при истечении JWT и декодированием типа `T`.
    private func performInternal<T: Decodable>(
        _ request: URLRequest,
        retryOnJWTExpired: Bool
    ) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let bodyString = String(data: data, encoding: .utf8) {
                AppLogger.debug(
                """
                ===== Supabase RAW RESPONSE =====
                URL: \(request.url?.absoluteString ?? "nil")
                Status: \((response as? HTTPURLResponse)?.statusCode ?? -1)
                Body: \(bodyString)
                =================================
                """
                )
            }
            
            guard let http = response as? HTTPURLResponse,
                  200..<300 ~= http.statusCode else {
                
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
                
                if retryOnJWTExpired && isJWTExpired(status: status, body: bodyString) {
                    AppLogger.debug("JWT expired, trying to refresh session and retry")
                    try await authService.refreshSession()
                    
                    var newRequest = request
                    await applyAuthHeaders(to: &newRequest)
                    return try await performInternal(newRequest, retryOnJWTExpired: false)
                }
                
                AppLogger.error(
                """
                ===== Supabase REST error =====
                Status: \(status)
                Body: \(bodyString)
                ===============================
                """
                )
                throw AppError.supabase(status: status, message: bodyString)
            }
            
            do {
                return try decode(T.self, from: data)
            } catch {
                let rawBody = String(data: data, encoding: .utf8) ?? "<no body>"
                AppLogger.error(
                """
                ===== DECODING ERROR =====
                Type: \(T.self)
                Error: \(error)
                Raw body: \(rawBody)
                ==========================
                """
                )
                throw AppError.decoding(underlying: error)
            }
        } catch let error as AppError {
            throw error
        } catch {
            AppLogger.error(
            """
            ===== URLSESSION ERROR =====
            URL: \(request.url?.absoluteString ?? "nil")
            Error: \(error)
            ============================
            """
            )
            throw AppError.network(underlying: error)
        }
    }
}
