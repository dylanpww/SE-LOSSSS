import Foundation

// MARK: - LostItemReport

/// A report of a lost or found item submitted by a UC student or staff member.
/// Conforms to Codable for direct Firestore document mapping.
/// No methods beyond init — all logic lives in ItemViewModel or ReportService.
struct LostItemReport: Identifiable, Codable, Equatable {

    // MARK: - Properties

    let id: String
    let title: String
    let location: String
    let date: Date
    let description: String
    let status: ItemStatus
    let imageUrl: String?
    let reporterId: String
    let reporterName: String
    let reporterEmail: String
    let createdAt: Date

    // MARK: - Init

    /// Creates a new LostItemReport.
    /// - Parameters:
    ///   - id: Firestore document ID (auto-generated if omitted)
    ///   - title: Short item name displayed in the listing card
    ///   - location: Campus location where item was lost or found
    ///   - date: Date the event occurred
    ///   - description: Detailed description for identification purposes
    ///   - status: Whether the item is lost or found
    ///   - imageUrl: Optional Cloud Storage URL for the item photo
    ///   - reporterId: UID of the submitting user
    ///   - reporterName: Display name of submitting user
    ///   - reporterEmail: Email of submitting user (masked in public board per NFR-02)
    ///   - createdAt: Firestore server timestamp of report creation
    init(
        id: String = UUID().uuidString,
        title: String,
        location: String,
        date: Date = Date(),
        description: String,
        status: ItemStatus,
        imageUrl: String? = nil,
        reporterId: String = "",
        reporterName: String = "",
        reporterEmail: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.location = location
        self.date = date
        self.description = description
        self.status = status
        self.imageUrl = imageUrl
        self.reporterId = reporterId
        self.reporterName = reporterName
        self.reporterEmail = reporterEmail
        self.createdAt = createdAt
    }
}
