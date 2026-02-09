import UIKit

final class TestUserService: UserService {
    
    private let testUser = User(
        login: "test",
        fullName: "Test User",
        avatar: UIImage(named: "Debug") ?? UIImage(),
        status: "Debug build"
        )
      
    func getUser(login: String) -> User? {
        return login == testUser.login ? testUser : nil
    }
}
