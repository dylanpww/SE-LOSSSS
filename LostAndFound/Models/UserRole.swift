import Foundation

// MARK: - UserRole

/// Role assigned to a UC Lost & Found user.
/// Enforced via RBAC middleware in RootView and AdminTabView routing.
enum UserRole: String, Codable, CaseIterable {
    case student = "student"
    case admin   = "admin"
}
