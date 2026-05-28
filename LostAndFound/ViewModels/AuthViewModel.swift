import Foundation
import SwiftUI
import os

// MARK: - AuthViewModel

/// Drives the Login and Register screens.
/// Translates AuthService results into @Published UI state.
/// No business logic lives in Views — all validation and service calls are here.
@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: - Properties

    @Published var currentUser: UCUser?
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let authService: AuthService
    private let logger = Logger(
        subsystem: "com.uc.lostfound",
        category: "AuthViewModel"
    )


    // MARK: - Init

    /// Creates an AuthViewModel with an injected AuthService.
    /// - Parameter authService: Service handling Firebase Auth calls; defaults to shared instance
    init(authService: AuthService = .shared) {
        self.authService = authService
    }


    // MARK: - Public Methods

    /// Attempts to sign in a user with university email and password.
    /// - Parameters:
    ///   - email: University email address
    ///   - password: Account password
    func login(email: String, password: String) async {
        guard validateLoginInputs(email: email, password: password) else { return }

        isLoading = true
        errorMessage = nil

        let result = await authService.login(email: email, password: password)

        isLoading = false

        switch result {
        case .success(let user):
            currentUser = user
            isLoggedIn = true
            logger.info("Auth state: signed in as \(user.role.rawValue)")
        case .failure(let error):
            errorMessage = error.errorDescription
            logger.warning("Login failed: \(error.localizedDescription)")
        }
    }

    /// Registers a new student account using a typed RegisterRequest.
    /// - Parameter request: All registration form fields wrapped in a RegisterRequest
    func register(request: RegisterRequest) async {
        guard validateRegisterRequest(request) else { return }

        isLoading = true
        errorMessage = nil

        let result = await authService.register(request: request)

        isLoading = false

        switch result {
        case .success(let user):
            currentUser = user
            isLoggedIn = true
            logger.info("Registration succeeded: \(user.email, privacy: .private)")
        case .failure(let error):
            errorMessage = error.errorDescription
            logger.warning("Registration failed: \(error.localizedDescription)")
        }
    }

    /// Signs out the current user and resets all auth state.
    func logout() {
        authService.logout()
        currentUser = nil
        isLoggedIn = false
        errorMessage = nil
        logger.info("Auth state: signed out")
    }

    /// Clears any displayed error message.
    func clearError() {
        errorMessage = nil
    }


    // MARK: - Private Helpers

    /// Validates login form inputs and sets errorMessage on failure.
    /// - Returns: true if all inputs are valid
    private func validateLoginInputs(email: String, password: String) -> Bool {
        guard email.isNotBlank, password.isNotBlank else {
            errorMessage = AppError.invalidInput.errorDescription
            return false
        }
        guard email.isValidUCEmail else {
            errorMessage = AppError.invalidDomain.errorDescription
            return false
        }
        return true
    }

    /// Validates registration form inputs and sets errorMessage on failure.
    /// - Parameter request: The RegisterRequest to validate
    /// - Returns: true if all inputs pass validation
    private func validateRegisterRequest(_ request: RegisterRequest) -> Bool {
        guard request.name.isNotBlank,
              request.email.isNotBlank,
              request.studentId.isNotBlank,
              request.password.isNotBlank,
              request.confirmPassword.isNotBlank else {
            errorMessage = AppError.invalidInput.errorDescription
            return false
        }
        guard request.email.isValidUCEmail else {
            errorMessage = AppError.invalidDomain.errorDescription
            return false
        }
        guard request.password.meetsMinLength(8) else {
            errorMessage = AppError.weakPassword.errorDescription
            return false
        }
        guard request.password == request.confirmPassword else {
            errorMessage = AppError.passwordMismatch.errorDescription
            return false
        }
        return true
    }
}
