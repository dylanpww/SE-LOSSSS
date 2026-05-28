import Foundation

// MARK: - ItemStatus

/// Indicates whether a LostItemReport describes a lost or found item.
/// Raw value is displayed directly as a badge label in the UI.
enum ItemStatus: String, Codable, CaseIterable {
    case lost  = "LOST"
    case found = "FOUND"
}
