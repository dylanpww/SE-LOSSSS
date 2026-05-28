import Foundation
import FirebaseFirestore
import os

// MARK: - ClaimService

/// Handles all Claim CRUD operations against Cloud Firestore.
/// Isolates Firestore SDK calls per the Service/Repository pattern (Coding Agreement §05).
final class ClaimService {

    // MARK: - Properties

    static let shared = ClaimService()

    private let logger = Logger(
        subsystem: "com.uc.lostfound",
        category: "ClaimService"
    )

    // MARK: - Init

    private init() {}

    // MARK: - Public Methods

    /// Fetches all claims, optionally filtered to a single item.
    /// - Parameter itemId: Optional Firestore document ID to filter by
    /// - Returns: Array of Claim or AppError on failure
    func fetchClaims(for itemId: String? = nil) async -> Result<[Claim], AppError> {
        do {
            // Build query — filter by itemId if provided, otherwise fetch all
            let query: Query
            if let itemId {
                query = Firestore.firestore()
                    .collection("claims")
                    .whereField("itemId", isEqualTo: itemId)
            } else {
                query = Firestore.firestore()
                    .collection("claims")
            }

            let snapshot = try await query.getDocuments()
            let claims = snapshot.documents.compactMap { document in
                try? document.data(as: Claim.self)
            }
            logger.info("Fetched \(claims.count) claims")
            return .success(claims)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }

    /// Submits a new ownership claim for a found item.
    /// Duplicate-claim guard: rejects if the claimant has already claimed this item.
    /// - Parameters:
    ///   - itemId: Firestore document ID of the associated LostItemReport
    ///   - claimData: Fully populated Claim model from the claimant
    /// - Returns: Created Claim or AppError on failure
    func submitClaim(
        itemId: String,
        claimData: Claim
    ) async -> Result<Claim, AppError> {
        guard itemId.isNotBlank else {
            return .failure(.invalidInput)
        }

        // Duplicate claim guard — check Firestore before inserting
        let alreadyClaimed = await hasClaimed(itemId: itemId, userId: claimData.claimantId)
        guard !alreadyClaimed else {
            return .failure(.unknown("You have already submitted a claim for this item."))
        }

        do {
            try Firestore.firestore()
                .collection("claims")
                .document(claimData.id)
                .setData(from: claimData)

            logger.info("Claim submitted for item: \(itemId)")
            return .success(claimData)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }

    /// Updates the approval status of a claim. Admin-only operation (enforced by RBAC).
    /// - Parameters:
    ///   - claimId: Firestore document ID of the claim to update
    ///   - newStatus: Target ClaimStatus (.approved or .rejected)
    /// - Returns: Updated Claim or AppError on failure
    func updateClaimStatus(
        claimId: String,
        newStatus: ClaimStatus
    ) async -> Result<Claim, AppError> {
        guard claimId.isNotBlank else {
            return .failure(.invalidInput)
        }

        do {
            // Update only the claimStatus field — preserves all other claim data
            try await Firestore.firestore()
                .collection("claims")
                .document(claimId)
                .updateData(["claimStatus": newStatus.rawValue])

            // Fetch the updated document to return the full Claim object
            let document = try await Firestore.firestore()
                .collection("claims")
                .document(claimId)
                .getDocument()

            guard let updatedClaim = try? document.data(as: Claim.self) else {
                return .failure(.unknown("Could not read updated claim."))
            }

            logger.info("Claim \(claimId) updated to: \(newStatus.rawValue)")
            return .success(updatedClaim)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }

    /// Checks Firestore whether a user has already claimed a specific item.
    /// Used as a duplicate-claim guard before allowing submission.
    /// - Parameters:
    ///   - itemId: Firestore document ID of the report
    ///   - userId: UID of the user to check
    /// - Returns: true if an existing claim is found
    func hasClaimed(itemId: String, userId: String) async -> Bool {
        do {
            let snapshot = try await Firestore.firestore()
                .collection("claims")
                .whereField("itemId", isEqualTo: itemId)
                .whereField("claimantId", isEqualTo: userId)
                .getDocuments()

            // Guard domain — if any document exists the user has already claimed
            return !snapshot.documents.isEmpty
        } catch {
            // Fail safe — if the check fails, allow submission
            return false
        }
    }
}
