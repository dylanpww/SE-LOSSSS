import SwiftUI

// MARK: - MyReportsView

/// Displays all reports submitted by the currently authenticated user.
/// Provides delete functionality with cascading removal (NFR-08 UU PDP compliance).
/// No business logic — all deletion logic lives in ItemViewModel.
struct MyReportsView: View {

    // MARK: - Properties

    @EnvironmentObject private var itemViewModel: ItemViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel

    @State private var selectedReport: LostItemReport? = nil
    @State private var reportToDelete: LostItemReport? = nil
    @State private var showDeleteConfirm: Bool = false

    private var myReports: [LostItemReport] {
        guard let userId = authViewModel.currentUser?.id else { return [] }
        return itemViewModel.reports(for: userId)
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            Group {
                if myReports.isEmpty {
                    emptyState
                } else {
                    reportList
                }
            }
            .background(AppColors.secondary)
            .navigationTitle("My Reports")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedReport) { report in
                ItemDetailView(report: report)
                    .environmentObject(itemViewModel)
                    .environmentObject(authViewModel)
            }
            .alert("Delete Listing", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) { confirmDelete() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(
                    "This will permanently remove the listing and all associated claims. "
                    + "This action cannot be undone."
                )
            }
        }
    }

    // MARK: - Private Sections

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text")
                .font(.system(size: 56))
                .foregroundColor(AppColors.separator)
            Text("No Reports Yet")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Your reported lost and found items will appear here.")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private var reportList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(myReports) { report in
                    MyReportCard(
                        report: report,
                        claimCount: itemViewModel.claims(for: report.id).count
                    ) {
                        selectedReport = report
                    } onDelete: {
                        reportToDelete = report
                        showDeleteConfirm = true
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Private Helpers

    /// Delegates confirmed deletion to ItemViewModel.
    private func confirmDelete() {
        guard let report = reportToDelete,
              let userId = authViewModel.currentUser?.id else { return }
        Task {
            await itemViewModel.deleteReport(
                reportId: report.id,
                userId: userId
            )
        }
    }
}


// MARK: - MyReportCard

/// Individual report card for MyReportsView including a delete control.
private struct MyReportCard: View {

    // MARK: - Properties

    let report: LostItemReport
    let claimCount: Int
    let onTap: () -> Void
    let onDelete: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.separator)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(report.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)

                    Text(report.location)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)

                    Text(report.date.formatted(as: "dd MMM yyyy"))
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)

                    HStack(spacing: 6) {
                        StatusBadge(status: report.status)
                        if claimCount > 0 {
                            Text("\(claimCount) claim\(claimCount > 1 ? "s" : "")")
                                .font(.caption2)
                                .foregroundColor(AppColors.primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppColors.primary.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(8)
                }
            }
            .padding(14)
            .background(AppColors.card)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppColors.separator, lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
