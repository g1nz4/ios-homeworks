import Foundation

struct LoginInspector: LogInViewControllerDelegate {
    func check(login: String, password: String) -> Bool {
       return Checker.shared.check(login: login, password: password)
    }
}
