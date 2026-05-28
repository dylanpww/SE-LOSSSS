import Foundation

// MARK: - AppError

/// Centralised error type used across all Result<T, AppError> returns.
/// Conforms to LocalizedError so UI can directly display errorDescription.
enum AppError: LocalizedError {

    case invalidDomain
    case invalidInput
    case emailAlreadyInUse
    case weakPassword
    case passwordMismatch
    case wrongCredentials
    case userNotFound
    case permissionDenied
    case networkError
    case unknown(String)

    // MARK: - Error Description

    var errorDescription: String? {
        switch self {
        case .invalidDomain:
            return "Only @ciputra.ac.id email addresses are permitted."
        case .invalidInput:
            return "Please fill in all required fields."
        case .emailAlreadyInUse:
            return "An account with this email already exists."
        case .weakPassword:
            return "Password must be at least 8 characters."
        case .passwordMismatch:
            return "Passwords do not match."
        case .wrongCredentials:
            return "Incorrect email or password."
        case .userNotFound:
            return "No account found with that email."
        case .permissionDenied:
            return "You do not have permission to perform this action."
        case .networkError:
            return "Network error. Please check your connection."
        case .unknown(let message):
            return message
        }
    }
}
