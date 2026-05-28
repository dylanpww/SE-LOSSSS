import Foundation

// MARK: - Claim

/// Represents an ownership claim submitted by a user for a found item.
/// Conforms to Codable for direct Firestore document mapping.
/// No methods beyond init — all logic lives in ItemViewModel or ClaimService.
struct Claim: Identifiable, Codable, Equatable {

    // MARK: - Properties

    let id: String
    let itemId: String
    let claimantId: String
    let claimantName: String
    let claimantEmail: String
    let message: String
    var claimStatus: ClaimStatus
    let createdAt: Date

    // MARK: - Init

    /// Creates a new Claim.
    /// - Parameters:
    ///   - id: Firestore document ID (auto-generated if omitted)
    ///   - itemId: Firestore document ID of the associated LostItemReport
    ///   - claimantId: UID of the claiming user
    ///   - claimantName: Display name of the claimant
    ///   - claimantEmail: Email of the claimant (hidden from public until approved — NFR-02)
    ///   - message: Ownership evidence provided by the claimant
    ///   - claimStatus: Current approval state; defaults to .pending
    ///   - createdAt: Firestore server timestamp of claim submission
    init(
        id: String = UUID().uuidString,
        itemId: String,
        claimantId: String,
        claimantName: String,
        claimantEmail: String,
        message: String,
        claimStatus: ClaimStatus = .pending,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.itemId = itemId
        self.claimantId = claimantId
        self.claimantName = claimantName
        self.claimantEmail = claimantEmail
        self.message = message
        self.claimStatus = claimStatus
        self.createdAt = createdAt
    }
}
