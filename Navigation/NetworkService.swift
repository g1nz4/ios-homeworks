import Foundation

struct NetworkService {
    
    static func urlSessionAsync(srtingURL: String) async {
        do {
            guard let url = URL(string: srtingURL) else { return }
            let (data, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                print("\nDATA: \(String(decoding: data, as: UTF8.self))")
                print("\nRESPONSE STATUS: \(httpResponse.statusCode)")
                print("\nRESPONSE HEADER: \(httpResponse.allHeaderFields)")
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}
