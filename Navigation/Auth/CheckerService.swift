import Foundation
import FirebaseAuth

protocol CheckerServiceProtocol {
    func checkCredentials(
        email: String,
        password: String,
        completion: @escaping (Result<Void, Error>) -> Void
    )
    
    func signUp(
        email: String,
        password: String,
        completion: @escaping (Result<Void, Error>) -> Void
    )
}

final class CheckerService: CheckerServiceProtocol {
    func checkCredentials(
        email: String,
        password: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ){
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let _ = authResult, error == nil {
                completion(.success(()))
            } else if let error {
                completion(.failure(error))
            }
        }
    }
    
    func signUp(
        email: String,
        password: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ){
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let _ = authResult, error == nil {
                completion(.success(()))
                return
            }
            
            if let nsError = error as NSError?,
               nsError.domain == AuthErrorDomain,
               let code = AuthErrorCode.Code(rawValue: nsError.code),
               code == .emailAlreadyInUse {
                let message = "Пользователь с таким email уже зарегистрирован."
                completion(.failure(NSError(
                    domain: "SignUp",
                    code: nsError.code,
                    userInfo: [NSLocalizedDescriptionKey: message]
                )))
            } else if let error {
                completion(.failure(error))
            }
        }
    }
}
