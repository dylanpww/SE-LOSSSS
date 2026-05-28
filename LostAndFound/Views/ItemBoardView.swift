import SwiftUI

// MARK: - ItemBoardView

/// Searchable catalogue of all active lost and found reports.
/// Satisfies NFR-03 (search latency) and NFR-05 (3-tap navigation).
/// No business logic — all filtering and fetching lives in ItemViewModel.
struct ItemBoardView: View {

    // MARK: - Properties

    @EnvironmentObject private var itemViewModel: ItemViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel

    @Binding var showAddListing: Bool

    @State private var searchText: String = ""
    @State private var filterStatus: ItemStatus? = nil
    @State private var selectedReport: LostItemReport? = nil

    private var filteredReports: [LostItemReport] {
        itemViewModel.filteredReports(search: searchText, filter: filterStatus)
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerBar
                Divider()
                contentArea
            }
            .background(AppColors.secondary)
            .navigationBarHidden(true)
            .sheet(item: $selectedReport) { report in
                ItemDetailView(report: report)
                    .environmentObject(itemViewModel)
                    .environmentObject(authViewModel)
            }
        }
    }

    // MARK: - Private Sections

    private var headerBar: some View {
        VStack(spacing: 12) {
            Text("UC LOST & FOUND")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.textSecondary)
                TextField("Search lost items...", text: $searchText)
                    .font(.system(size: 15))
            }
            .padding(12)
            .background(AppColors.secondary)
            .cornerRadius(12)
            .padding(.horizontal, 16)

            HStack(spacing: 0) {
                FilterChip(title: "All items", isSelected: filterStatus == nil) {
                    filterStatus = nil
                }
                FilterChip(title: "Lost", isSelected: filterStatus == .lost) {
                    filterStatus = .lost
                }
                FilterChip(title: "Found", isSelected: filterStatus == .found) {
                    filterStatus = .found
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(AppColors.background)
    }

    @ViewBuilder
    private var contentArea: some View {
        if itemViewModel.isLoading && itemViewModel.reports.isEmpty {
            loadingState
        } else if filteredReports.isEmpty {
            emptyState
        } else {
            reportList
        }
    }

    private var loadingState: some View {
        VStack {
            Spacer()
            ProgressView("Loading items...")
                .foregroundColor(AppColors.textSecondary)
            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray.fill")
                .font(.system(size: 48))
                .foregroundColor(AppColors.separator)
            Text("No items found")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
            Spacer()
        }
    }

    private var reportList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(filteredReports) { report in
                    Button(action: { selectedReport = report }) {
                        ItemCard(report: report)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, 100)
        }
    }
}
