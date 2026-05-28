import Foundation
import FirebaseFirestore
import FirebaseStorage
import UIKit

// MARK: - ReportService

/// Handles all LostItemReport CRUD operations against Cloud Firestore.
/// Isolates Firestore SDK calls per the Service/Repository pattern (Coding Agreement §05).
final class ReportService {

    // MARK: - Properties

    static let shared = ReportService()

    // MARK: - Init

    private init() {}

    // MARK: - Public Methods

    /// Fetches all active reports ordered by createdAt descending.
    /// - Returns: Array of LostItemReport or AppError on failure
    func fetchAllReports() async -> Result<[LostItemReport], AppError> {
        do {
            let snapshot = try await Firestore.firestore()
                .collection("reports")
                .order(by: "createdAt", descending: true)
                .getDocuments()

            let reports = snapshot.documents.compactMap { document in
                try? document.data(as: LostItemReport.self)
            }
            return .success(reports)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }

    /// Fetches all reports submitted by a specific user.
    /// - Parameter userId: Firestore UID of the reporter
    /// - Returns: Filtered array of LostItemReport or AppError
    func fetchReports(for userId: String) async -> Result<[LostItemReport], AppError> {
        guard userId.isNotBlank else {
            return .failure(.invalidInput)
        }

        do {
            let snapshot = try await Firestore.firestore()
                .collection("reports")
                .whereField("reporterId", isEqualTo: userId)
                .getDocuments()

            let userReports = snapshot.documents.compactMap { document in
                try? document.data(as: LostItemReport.self)
            }
            return .success(userReports)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }

    /// Creates a new report document in Firestore.
    /// Optionally uploads an image to Cloud Storage first and stores the URL.
    /// - Parameters:
    ///   - report: Fully populated LostItemReport to persist
    ///   - imageData: Optional raw image bytes to upload
    /// - Returns: Created LostItemReport with imageUrl filled in, or AppError
    func createReport(
        _ report: LostItemReport,
        imageData: Data? = nil
    ) async -> Result<LostItemReport, AppError> {
        guard report.title.isNotBlank, report.location.isNotBlank else {
            return .failure(.invalidInput)
        }

        do {
            var finalReport = report

            // Upload image first if provided, then store the URL in the report
            if let imageData {
                let imageUrl = try await uploadImage(imageData, reportId: report.id)
                finalReport = LostItemReport(
                    id: report.id,
                    title: report.title,
                    location: report.location,
                    date: report.date,
                    description: report.description,
                    status: report.status,
                    imageUrl: imageUrl,
                    reporterId: report.reporterId,
                    reporterName: report.reporterName,
                    reporterEmail: report.reporterEmail,
                    createdAt: report.createdAt
                )
            }

            try Firestore.firestore()
                .collection("reports")
                .document(finalReport.id)
                .setData(from: finalReport)

            return .success(finalReport)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }

    /// Permanently deletes a report from Firestore.
    /// Satisfies NFR-08 UU PDP No. 27/2022 for user-initiated deletion.
    /// - Parameters:
    ///   - reportId: Firestore document ID of the report to delete
    ///   - userId: UID of requesting user
    /// - Returns: Void on success or AppError on failure
    func deleteReport(
        reportId: String,
        userId: String
    ) async -> Result<Void, AppError> {
        guard reportId.isNotBlank else {
            return .failure(.invalidInput)
        }

        do {
            try await Firestore.firestore()
                .collection("reports")
                .document(reportId)
                .delete()
            return .success(())
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }

    // MARK: - Private Helpers

    /// Uploads raw image bytes to Firebase Storage and returns the download URL.
    /// - Parameters:
    ///   - imageData: Raw image bytes from PHPickerViewController
    ///   - reportId: Used as the filename for later cascading delete
    /// - Returns: Public HTTPS download URL string
    private func uploadImage(
        _ imageData: Data,
        reportId: String
    ) async throws -> String {
        guard let compressed = UIImage(data: imageData)?
                .jpegData(compressionQuality: 0.8) else {
            throw AppError.invalidInput
        }

        let storageRef = Storage.storage()
            .reference()
            .child("items/\(reportId).jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await storageRef.putDataAsync(compressed, metadata: metadata)

        let downloadUrl = try await storageRef.downloadURL()
        return downloadUrl.absoluteString
    }
}
