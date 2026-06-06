import LocalAuthentication

enum LocalAuthError: Error {
    case biometryNotAvailable
    case authenticationFailed
    case canceled
    case unknown(Error)
}

final class LocalAuthorizationService {
    
    enum BiometryType {
        case none
        case touchID
        case faceID
    }
    
    private let context = LAContext()
    
    var biometryType: BiometryType {
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        guard canEvaluate else { return .none }
        
        
        switch context.biometryType {
            case .none:    return .none
            case .touchID: return .touchID
            case .faceID:  return .faceID
            case .opticID: return .none
            @unknown default: return .none
        }
    }

    func authorizeIfPossible() async throws -> Bool {
        var error: NSError?
        let policy = LAPolicy.deviceOwnerAuthenticationWithBiometrics

        guard context.canEvaluatePolicy(policy, error: &error) else {
            if let laError = error as? LAError {
                throw mapLAError(laError)
            } else if let error {
                throw LocalAuthError.unknown(error)
            } else {
                throw LocalAuthError.biometryNotAvailable
            }
        }

        let reason = "Авторизуйтесь с помощью биометрии"

        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(policy, localizedReason: reason) { success, evalError in
                if success {
                    continuation.resume(returning: true)
                } else if let laError = evalError as? LAError {
                    continuation.resume(throwing: self.mapLAError(laError))
                } else if let evalError {
                    continuation.resume(throwing: LocalAuthError.unknown(evalError))
                } else {
                    continuation.resume(throwing: LocalAuthError.authenticationFailed)
                }
            }
        }
    }

    private func mapLAError(_ error: LAError) -> LocalAuthError {
        switch error.code {
        case .biometryNotAvailable, .biometryNotEnrolled, .passcodeNotSet, .biometryLockout:
            return .biometryNotAvailable
        case .userCancel, .systemCancel, .appCancel:
            return .canceled
        case .authenticationFailed, .userFallback:
            return .authenticationFailed
        default:
            return .unknown(error)
        }
    }
}
