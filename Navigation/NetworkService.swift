import Foundation

struct NetworkService {
    
    static func request(
        for configuration: AppConfiguration,
        completion: @escaping(Result<String, NetworkError>) -> Void
    ) {
        let url: URL
        switch configuration {
        case .people(let configURL),
             .starship(let configURL),
             .planet(let configURL):
            url = configURL
        }
        
        print("Request:", url.absoluteString)
        
        let session = URLSession.shared
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                print(error.localizedDescription)
                completion(.failure(.requestFailed(error)))
                return
            }

            guard let httpurlresponse = response as? HTTPURLResponse else {
                completion(.failure(.errorReceivingData))
                return
            }

            if httpurlresponse.statusCode != 200 {
                print("Ошибка получения данных:", httpurlresponse.statusCode)
                completion(.failure(.errorReceivingData))
                return
            }

            print("STATUS CODE: ", httpurlresponse.statusCode)
            print("ALL HEADER FIELDS:")
            httpurlresponse.allHeaderFields.forEach { key, value in
                print("\(key): \(value)")
            }

            guard let data = data else {
                completion(.failure(.noData))
                return
            }

            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
               
                guard let dictionary = jsonObject else {
                    completion(.failure(.decodingFailed))
                    return
                }
                
                let answer = dictionary
                    .map { "\($0.key): \($0.value)" }
                    .joined(separator: "\n")

                completion(.success(answer))
            } catch {
                print("Ошибка декодирования JSON:", error)
                completion(.failure(.decodingFailed))
            }
        }
        task.resume()
    }
}
/*
 Ошибка при выключенном интернете:
 
 The Internet connection appears to be offline.
FAILURE :(
 requestFailed(Error Domain=NSURLErrorDomain Code=-1009 "The Internet connection appears to be offline."
*/
