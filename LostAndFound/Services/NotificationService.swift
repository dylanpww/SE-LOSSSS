import Foundation
import os

// MARK: - NotificationService

/// Handles push notification dispatch via Firebase Cloud Messaging (FCM).
/// All FCM SDK calls and Cloud Function triggers are isolated in this service.
/// In production: replace stubs with real FCM token lookup and send calls.
final class NotificationService {

    // MARK: - Properties

    /// Shared singleton instance — inject via init for unit testing.
    static let shared = NotificationService()

    private let logger = Logger(
        subsystem: "com.uc.lostfound",
        category: "NotificationService"
    )


    // MARK: - Init

    private init() {}


    // MARK: - Public Methods

    /// Notifies a report owner when a new claim is submitted for their item.
    /// - Parameters:
    ///   - reporterUserId: Firestore UID of the report owner
    ///   - itemTitle: Title of the claimed item used in the notification body
    func notifyReporterOfNewClaim(
        reporterUserId: String,
        itemTitle: String
    ) async {
        guard reporterUserId.isNotBlank else { return }

        // Production replacement:
        // 1. Fetch FCM token: Firestore.firestore().collection("users")
        //        .document(reporterUserId).getDocument()["fcmToken"]
        // 2. POST to FCM v1 API via a Cloud Function:
        //    functions.httpsCallable("sendClaimNotification")
        //        .call(["token": fcmToken, "itemTitle": itemTitle])

        logger.info("Claim notification sent to \(reporterUserId) for: \(itemTitle)")
    }

    /// Notifies a claimant when their claim status changes to approved or rejected.
    /// - Parameters:
    ///   - claimantUserId: Firestore UID of the claimant
    ///   - newStatus: Updated ClaimStatus to include in the notification message
    func notifyClaimantOfStatusChange(
        claimantUserId: String,
        newStatus: ClaimStatus
    ) async {
        guard claimantUserId.isNotBlank else { return }

        // Production replacement:
        // Cloud Function triggered by Firestore onUpdate for claims/{claimId}
        // automatically reads the new status and sends FCM to the claimant's token

        logger.info("Status notification sent to \(claimantUserId): \(newStatus.rawValue)")
    }

    /// Sends a campus-wide broadcast notification to all registered users.
    /// Admin-only operation — caller must enforce RBAC before invoking.
    /// - Parameters:
    ///   - title: Notification title
    ///   - body: Notification body text
    func broadcastToAll(title: String, body: String) async {
        guard title.isNotBlank, body.isNotBlank else { return }

        // Production replacement:
        // Cloud Function: send FCM to the "all_students" topic
        // Messaging.messaging().send(to topic: "/topics/all_students", ...)

        logger.info("Broadcast sent — title: \(title)")
    }
}
