import Foundation
/// Клиент для REST‑запросов в Supabase (rest/v1/…).
/// Auth теперь делает официальный Supabase SDK, поэтому Auth‑часть отсюда убрали.
final class SupabaseRESTClient {
    /// JSON‑кодировщик для тела запросов
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
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
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
    
    /// Выполнить запрос без ожидания тела ответа (например, INSERT/UPDATE).
    func performVoid(_ request: URLRequest) async throws {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse,
              200..<300 ~= http.statusCode else {
            
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
            
            // generic‑ошибка Supabase с телом ответа для отладки
            throw NSError(
                domain: "Supabase",
                code: status,
                userInfo: [
                    NSLocalizedDescriptionKey: "Supabase error",
                    "status": status,
                    "body": bodyString
                ]
            )
        }
    }
    
    /// Выполнить запрос и декодировать JSON‑ответ в тип T.
    func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
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
                
                throw NSError(
                    domain: "Supabase",
                    code: status,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Supabase error",
                        "status": status,
                        "body": bodyString
                    ]
                )
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
                
                throw error
            }
        } catch {
            AppLogger.error(
                    """
                    ===== URLSESSION ERROR =====
                    URL: \(request.url?.absoluteString ?? "nil")
                    Error: \(error)
                    ============================
                    """
            )
            throw error
        }
    }
}
