import Foundation

// MARK: - ClaimStatus

/// Represents the lifecycle state of a submitted claim.
/// Raw value is displayed directly as a badge label in the UI.
enum ClaimStatus: String, Codable, CaseIterable {
    case pending  = "pending"
    case approved = "approved"
    case rejected = "rejected"
}
