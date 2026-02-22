import Foundation
import UIKit

protocol UserService {
    var user: User { get set }
    func getUser(login: String) -> User?
}

final class CurrentUserService: UserService {
    
    var user: User
    
    init(user: User) {
        self.user = user
    }
}

extension UserService {
    func getUser(login: String) -> User? {
        return login == user.login ? user : nil
    }
}
