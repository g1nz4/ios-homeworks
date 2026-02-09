import UIKit

protocol UserService {
    func getUser(login: String) -> User?
}

final class CurrentUserService: UserService {
    
    private let user: User
    
    init(user: User) {
        self.user = user
    }
    
    func getUser(login: String) -> User? {
        login == user.login ? user : nil
    }
}
