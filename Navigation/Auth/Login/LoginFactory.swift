import Foundation

protocol LoginFactoryProtocol {
    func makeLoginInspector() -> LoginInspector
}

struct LoginFactory: LoginFactoryProtocol {
    
    private let loginInspector: LoginInspector
   
   init(loginInspector: LoginInspector) {
       self.loginInspector = loginInspector
   }

    func makeLoginInspector() -> LoginInspector {
        return loginInspector
    }
}
