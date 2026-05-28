import Foundation
import FirebaseFirestore
import FirebaseAuth

final class AuthService {
    
    static let shared = AuthService()
    
    // MARK: - Init
    private init() {}
    
    // MARK: - Public Methods
    
    /// Validates that an email address belongs to the university domain.
    func validateDomain(_ email: String) -> Bool {
        email.isValidUCEmail
    }
    
    /// Authenticates a user with email and password.
    func login(
        email: String,
        password: String
    ) async -> Result<UCUser, AppError> {
        // Guard domain before Firebase call
        guard validateDomain(email) else {
            return .failure(.invalidDomain)
        }
        
        guard password.isNotBlank else {
            return .failure(.invalidInput)
        }
        
        // Wrap Firebase throwing calls in a do-catch block
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let user = try await fetchUserFromFirestore(uid: result.user.uid)
            return .success(user)
        } catch {
            return .failure(.wrongCredentials)
        }
    }
    
    /// Registers a new user inside Firebase Auth and records their profile in Firestore.
    func register(request: RegisterRequest) async -> Result<UCUser, AppError> {
        // Guard domain before Firebase call
        guard validateDomain(request.email) else {
            return .failure(.invalidDomain)
        }
        
        guard request.name.isNotBlank,
              request.studentId.isNotBlank else {
            return .failure(.invalidInput)
        }
        
        guard request.password.meetsMinLength(8) else {
            return .failure(.weakPassword)
        }
        
        guard request.password == request.confirmPassword else {
            return .failure(.passwordMismatch)
        }
        
        do {
            // FIX 1: Access email and password via the 'request' parameter
            let result = try await Auth.auth().createUser(withEmail: request.email, password: request.password)
            
            let newUser = UCUser(
                id: result.user.uid,
                name: request.name,
                email: request.email,
                role: .student,
                studentId: request.studentId
            )

            try Firestore.firestore()
                .collection("users")
                .document(result.user.uid)
                .setData(from: newUser)
            
            return .success(newUser)
        } catch {
            return .failure(.passwordMismatch)
        }
    }
    
    func logout() {
        try? Auth.auth().signOut()
    }
    
    // MARK: - Private Helpers
    
    // FIX 3: Implemented the missing Firestore retrieval method
    private func fetchUserFromFirestore(uid: String) async throws -> UCUser {
        let snapshot = try await Firestore.firestore()
            .collection("users")
            .document(uid)
            .getDocument()
        
        // This decodes the document directly into your UCUser structural model
        let user = try snapshot.data(as: UCUser.self)
        return user
    }
}
