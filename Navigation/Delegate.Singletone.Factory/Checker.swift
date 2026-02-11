import Foundation

final class Checker {
    
    static let shared = Checker()
    
    private let users: [String: String] = [
            "cat": "qwerty",
            "test": "debug"
        ]

    private init() {}
    
    func check(login: String, password: String) -> Bool {
        return users[login] == password
    }
}
