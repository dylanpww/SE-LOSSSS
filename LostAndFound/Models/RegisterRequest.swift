import Foundation

// MARK: - RegisterRequest

/// Parameter wrapper for AuthService.register() — satisfies §03 max-3-params rule.
/// Groups all registration inputs into a single typed struct.
struct RegisterRequest {

    // MARK: - Properties

    let name: String
    let email: String
    let studentId: String
    let password: String
    let confirmPassword: String
}
