import Foundation
import SwiftUI
import FirebaseFirestore
import os

// MARK: - ItemViewModel

/// Drives ItemBoardView, ItemDetailView, AddListingView, MyReportsView, and AdminViews.
/// Translates ReportService and ClaimService results into @Published UI state.
/// No business logic lives in Views — all service calls and state mutations are here.
@MainActor
final class ItemViewModel: ObservableObject {

    // MARK: - Properties

    @Published var reports: [LostItemReport] = []
    @Published var claims: [Claim] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var users: [UCUser] = []

    private let reportService: ReportService
    private let claimService: ClaimService
    private let notificationService: NotificationService
    private let logger = Logger(
        subsystem: "com.uc.lostfound",
        category: "ItemViewModel"
    )


    // MARK: - Init

    /// Creates an ItemViewModel with injected services.
    /// - Parameters:
    ///   - reportService: Service handling Firestore report operations
    ///   - claimService: Service handling Firestore claim operations
    ///   - notificationService: Service handling FCM push notifications
    init(
        reportService: ReportService = .shared,
        claimService: ClaimService = .shared,
        notificationService: NotificationService = .shared
    ) {
        self.reportService = reportService
        self.claimService = claimService
        self.notificationService = notificationService
    }


    // MARK: - Public Methods — Reports

    /// Loads all active reports from Firestore and updates the published reports array.
    func fetchAllReports() async {
        isLoading = true
        errorMessage = nil

        let result = await reportService.fetchAllReports()

        isLoading = false

        switch result {
        case .success(let fetched):
            reports = fetched
            logger.info("Item board loaded: \(fetched.count) reports")
        case .failure(let error):
            errorMessage = error.errorDescription
        }
    }

    /// Loads all claims from Firestore and updates the published claims array.
    func fetchAllClaims() async {
        let result = await claimService.fetchClaims()
        switch result {
        case .success(let fetched):
            claims = fetched
        case .failure(let error):
            errorMessage = error.errorDescription
        }
    }

    /// Creates and persists a new lost/found report.
    /// - Parameter report: Fully populated LostItemReport to submit
    func submitReport(_ report: LostItemReport, imageData: Data? = nil) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        let result = await reportService.createReport(report, imageData: imageData)

        isLoading = false

        switch result {
        case .success(let created):
            reports.insert(created, at: 0)
            successMessage = "Your listing has been posted!"
            logger.info("Report created: \(created.title)")
        case .failure(let error):
            errorMessage = error.errorDescription
        }
    }

    /// Deletes a report and triggers cascading removal of its claims via Cloud Function.
    /// Satisfies NFR-08 UU PDP compliance for user-initiated data deletion.
    /// - Parameters:
    ///   - reportId: Firestore document ID of the report
    ///   - userId: UID of requesting user (must match reporterId or hold admin role)
    func deleteReport(reportId: String, userId: String) async {
        errorMessage = nil

        let result = await reportService.deleteReport(reportId: reportId, userId: userId)

        switch result {
        case .success:
            reports.removeAll { $0.id == reportId }
            claims.removeAll { $0.itemId == reportId }
            logger.info("Report deleted: \(reportId)")
        case .failure(let error):
            errorMessage = error.errorDescription
        }
    }


    // MARK: - Public Methods — Claims

    /// Submits a claim for a found item and notifies the report owner via FCM.
    /// - Parameters:
    ///   - itemId: Firestore document ID of the found item report
    ///   - claim: Fully populated Claim model from the claimant
    func submitClaim(itemId: String, claim: Claim) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        let result = await claimService.submitClaim(itemId: itemId, claimData: claim)

        isLoading = false

        switch result {
        case .success(let created):
            claims.insert(created, at: 0)
            successMessage = "Your claim has been submitted!"
            await notificationService.notifyReporterOfNewClaim(
                reporterUserId: reporterIdFor(itemId: itemId),
                itemTitle: titleFor(itemId: itemId)
            )
        case .failure(let error):
            errorMessage = error.errorDescription
        }
    }

    /// Updates a claim's approval status. Admin-only action — enforce RBAC at call site.
    /// - Parameters:
    ///   - claimId: Firestore document ID of the claim
    ///   - newStatus: Target ClaimStatus (.approved or .rejected)
    func updateClaimStatus(claimId: String, newStatus: ClaimStatus) async {
        let result = await claimService.updateClaimStatus(
            claimId: claimId,
            newStatus: newStatus
        )
        switch result {
        case .success(let updated):
            if let index = claims.firstIndex(where: { $0.id == claimId }) {
                claims[index] = updated
            }
            
            if newStatus == .approved {
                    await markReportAsClaimed(itemId: updated.itemId)
            }
            
            await notificationService.notifyClaimantOfStatusChange(
                claimantUserId: updated.claimantId,
                newStatus: newStatus
            )
        case .failure(let error):
            errorMessage = error.errorDescription
        }
    }
    
    private func markReportAsClaimed(itemId: String) async {
        do {
            try await Firestore.firestore()
                .collection("reports")
                .document(itemId)
                .updateData(["status": ItemStatus.claimed.rawValue])

            if let index = reports.firstIndex(where: { $0.id == itemId }) {
                reports.remove(at: index)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Clears any displayed success message after the UI has consumed it.
    func clearSuccess() {
        successMessage = nil
    }

    /// Clears any displayed error message.
    func clearError() {
        errorMessage = nil
    }
    
    func fetchAllUsers() async {
        do {
            let snapshot = try await Firestore.firestore()
                .collection("users")
                .getDocuments()

            let fetchedUsers = snapshot.documents.compactMap { document in
                try? document.data(as: UCUser.self)
            }
            users = fetchedUsers
        } catch {
            errorMessage = error.localizedDescription
        }
    }


    // MARK: - Computed Helpers

    /// Filters reports by search text and optional status filter for the item board.
    /// - Parameters:
    ///   - search: Free-text search string (matches title and location)
    ///   - filter: Optional ItemStatus filter; nil returns all statuses
    /// - Returns: Filtered and ordered array of LostItemReport
    func filteredReports(search: String, filter: ItemStatus?) -> [LostItemReport] {
        reports.filter { report in
            
            guard report.status != .claimed else { return false }
            let matchesSearch = search.isEmpty
                || report.title.localizedCaseInsensitiveContains(search)
                || report.location.localizedCaseInsensitiveContains(search)
            let matchesFilter = filter == nil || report.status == filter
            return matchesSearch && matchesFilter
        }
    }

    /// Returns all claims associated with a specific report.
    /// - Parameter itemId: Firestore document ID of the report
    /// - Returns: Filtered array of Claim
    func claims(for itemId: String) -> [Claim] {
        claims.filter { $0.itemId == itemId }
    }

    /// Returns all reports submitted by a specific user.
    /// - Parameter userId: Firestore UID of the reporter
    /// - Returns: Filtered array of LostItemReport
    func reports(for userId: String) -> [LostItemReport] {
        reports.filter { $0.reporterId == userId }
    }

    /// Returns whether a specific user has already claimed a specific item.
    /// - Parameters:
    ///   - itemId: Firestore document ID of the report
    ///   - userId: UID of the user to check
    /// - Returns: true if an existing claim is found
    func hasClaimed(itemId: String, userId: String) async -> Bool {
        await claimService.hasClaimed(itemId: itemId, userId: userId)
    }

    /// Total number of lost-status reports (for admin dashboard stat card).
    var totalLost: Int {
        reports.filter { $0.status == .lost }.count
    }

    /// Total number of found-status reports (for admin dashboard stat card).
    var totalFound: Int {
        reports.filter { $0.status == .found }.count
    }

    /// Total number of claims with pending status (for admin dashboard stat card).
    var totalPendingClaims: Int {
        claims.filter { $0.claimStatus == .pending }.count
    }


    // MARK: - Private Helpers

    /// Returns the reporterId for a given item, used when dispatching notifications.
    private func reporterIdFor(itemId: String) -> String {
        reports.first { $0.id == itemId }?.reporterId ?? ""
    }

    /// Returns the title for a given item, used in notification body text.
    private func titleFor(itemId: String) -> String {
        reports.first { $0.id == itemId }?.title ?? "an item"
    }
}
