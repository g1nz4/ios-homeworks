import Foundation
import UIKit

final class TestUserService: UserService {
  
    var user: User = User(
        login: "test",
        fullName: "Test User",
        avatar: UIImage(named: "Debug") ?? UIImage(),
        status: "Debug build"
        )
}
