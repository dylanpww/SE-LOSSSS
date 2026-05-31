import SwiftUI

// MARK: - AdminTabView

/// Root navigation shell for admin users.
/// Uses native TabView — admin role confirmed by RBAC check in RootView.
struct AdminTabView: View {

    // MARK: - Body

    var body: some View {
        TabView {
            AdminDashboardView()
                .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }

            AdminItemsView()
                .tabItem { Label("Items", systemImage: "list.bullet") }

            AdminClaimsView()
                .tabItem { Label("Claims", systemImage: "doc.text.fill") }

            AdminUsersView()
                .tabItem { Label("Users", systemImage: "person.2.fill") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .accentColor(AppColors.primary)
    }
}


// MARK: - AdminDashboardView

/// Overview dashboard showing live stats and recent activity for administrators.
struct AdminDashboardView: View {

    // MARK: - Properties

    @EnvironmentObject private var itemViewModel: ItemViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    welcomeHeader
                    SectionHeader(title: "Overview")
                    statsGrid
                    SectionHeader(title: "Recent Items")
                    recentItemsList
                    pendingClaimsSection
                }
                .padding(16)
                .padding(.bottom, 20)
            }
            .background(AppColors.secondary)
            .navigationTitle("Admin Dashboard")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Private Sections

    private var welcomeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back,")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                Text(authViewModel.currentUser?.name ?? "Admin")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.15))
                    .frame(width: 48, height: 48)
                Text("AD")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.primary)
            }
        }
    }

    private var statsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
        ) {
            AdminStatCard(
                value: "\(itemViewModel.reports.count)",
                label: "Total Items",
                icon: "archivebox.fill",
                color: AppColors.primary
            )
            AdminStatCard(
                value: "\(itemViewModel.totalLost)",
                label: "Lost Items",
                icon: "exclamationmark.triangle.fill",
                color: AppColors.lost
            )
            AdminStatCard(
                value: "\(itemViewModel.totalFound)",
                label: "Found Items",
                icon: "checkmark.circle.fill",
                color: AppColors.found
            )
            AdminStatCard(
                value: "\(itemViewModel.totalPendingClaims)",
                label: "Pending Claims",
                icon: "clock.fill",
                color: AppColors.admin
            )
        }
    }

    private var recentItemsList: some View {
        ForEach(itemViewModel.reports.prefix(4)) { report in
            AdminItemRow(report: report)
        }
    }

    @ViewBuilder
    private var pendingClaimsSection: some View {
        let pending = itemViewModel.claims.filter { $0.claimStatus == .pending }
        if !pending.isEmpty {
            SectionHeader(title: "Pending Claims")
            ForEach(pending.prefix(3)) { claim in
                AdminClaimCard(claim: claim)
                    .environmentObject(itemViewModel)
            }
        }
    }
}


// MARK: - AdminStatCard

struct AdminStatCard: View {

    // MARK: - Properties

    let value: String
    let label: String
    let icon: String
    let color: Color

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.card)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppColors.separator, lineWidth: 0.5)
        )
    }
}


// MARK: - AdminItemRow

struct AdminItemRow: View {

    // MARK: - Properties

    let report: LostItemReport

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let urlString = report.imageUrl,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .empty:
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppColors.separator)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.7)
                                )
                        case .failure:
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppColors.separator)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppColors.separator)
                        }
                    }
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.separator)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
            }
            .frame(width: 44, height: 44)
            .cornerRadius(10)
            .clipped()

            VStack(alignment: .leading, spacing: 2) {
                Text(report.title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                Text(report.location)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()
            StatusBadge(status: report.status)
        }
        .padding(12)
        .background(AppColors.card)
        .cornerRadius(10)
    }
}


// MARK: - AdminClaimCard

/// Claim card with approve / reject controls. Used in dashboard and claims view.
struct AdminClaimCard: View {

    // MARK: - Properties

    @EnvironmentObject private var itemViewModel: ItemViewModel
    let claim: Claim

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(claim.claimantName)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                ClaimStatusBadge(claimStatus: claim.claimStatus)
            }

            Text(claim.message)
                .font(.system(size: 13))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(2)

            if claim.claimStatus == .pending {
                HStack(spacing: 8) {
                    adminActionChip(
                        title: "Approve",
                        color: AppColors.found,
                        status: .approved
                    )
                    adminActionChip(
                        title: "Reject",
                        color: .red,
                        status: .rejected
                    )
                }
            }
        }
        .padding(12)
        .background(AppColors.card)
        .cornerRadius(10)
    }

    private func adminActionChip(
        title: String,
        color: Color,
        status: ClaimStatus
    ) -> some View {
        Button(action: {
            Task {
                await itemViewModel.updateClaimStatus(
                    claimId: claim.id,
                    newStatus: status
                )
            }
        }) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(color)
                .cornerRadius(8)
        }
    }
}


// MARK: - AdminItemsView

/// Full list of all reports with search, status filter, and delete controls.
struct AdminItemsView: View {

    // MARK: - Properties

    @EnvironmentObject private var itemViewModel: ItemViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel

    @State private var searchText: String = ""
    @State private var filterStatus: ItemStatus? = nil
    @State private var reportToDelete: LostItemReport? = nil
    @State private var showDeleteConfirm: Bool = false

    private var filteredReports: [LostItemReport] {
        itemViewModel.filteredReports(search: searchText, filter: filterStatus)
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBar
                filterBar
                Divider()
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredReports) { report in
                            HStack(spacing: 8) {
                                ItemCard(report: report)
                                deleteButton(for: report)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .background(AppColors.secondary)
            .navigationTitle("All Items")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Delete Item", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) { confirmDelete() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Permanently delete this listing and all associated claims?")
            }
        }
    }

    // MARK: - Private Sections

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)
            TextField("Search items...", text: $searchText)
        }
        .padding(12)
        .background(AppColors.secondary)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppColors.background)
    }

    private var filterBar: some View {
        HStack(spacing: 0) {
            FilterChip(title: "All",   isSelected: filterStatus == nil)   { filterStatus = nil }
            FilterChip(title: "Lost",  isSelected: filterStatus == .lost)  { filterStatus = .lost }
            FilterChip(title: "Found", isSelected: filterStatus == .found) { filterStatus = .found }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .background(AppColors.background)
    }

    private func deleteButton(for report: LostItemReport) -> some View {
        Button(action: {
            reportToDelete = report
            showDeleteConfirm = true
        }) {
            Image(systemName: "trash")
                .foregroundColor(.red)
                .padding(8)
        }
    }

    // MARK: - Private Helpers

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


// MARK: - AdminClaimsView

/// Full claims list with status filter tabs and approve / reject controls.
struct AdminClaimsView: View {

    // MARK: - Properties

    @EnvironmentObject private var itemViewModel: ItemViewModel
    @State private var filterStatus: ClaimStatus? = nil

    private var filteredClaims: [Claim] {
        guard let filter = filterStatus else { return itemViewModel.claims }
        return itemViewModel.claims.filter { $0.claimStatus == filter }
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                claimFilterBar
                Divider()
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredClaims) { claim in
                            AdminClaimCard(claim: claim)
                                .environmentObject(itemViewModel)
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 12)
                }
            }
            .background(AppColors.secondary)
            .navigationTitle("Claims")
            .navigationBarTitleDisplayMode(.inline)
            .task{
                await itemViewModel.fetchAllClaims()
            }
        }
    }

    // MARK: - Private Sections

    private var claimFilterBar: some View {
        HStack(spacing: 0) {
            claimChip(title: "All",      filter: nil)
            claimChip(title: "Pending",  filter: .pending)
            claimChip(title: "Approved", filter: .approved)
            claimChip(title: "Rejected", filter: .rejected)
        }
        .padding(12)
        .background(AppColors.background)
    }

    private func claimChip(title: String, filter: ClaimStatus?) -> some View {
        Button(action: { filterStatus = filter }) {
            Text(title)
                .font(
                    .system(
                        size: 13,
                        weight: filterStatus == filter ? .semibold : .regular
                    )
                )
                .foregroundColor(
                    filterStatus == filter
                        ? AppColors.textPrimary
                        : AppColors.textSecondary
                )
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(filterStatus == filter ? AppColors.card : Color.clear)
                .cornerRadius(16)
        }
    }
}


// MARK: - AdminUsersView

/// List of all registered users visible to administrators.
struct AdminUsersView: View {

    // MARK: - Properties
    @EnvironmentObject private var itemViewModel: ItemViewModel

    // MARK: - Body

    var body: some View {
            NavigationView {
                Group {
                    if itemViewModel.isLoading && itemViewModel.users.isEmpty {
                        VStack {
                            Spacer()
                            ProgressView("Loading users...")
                            Spacer()
                        }
                    } else if itemViewModel.users.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "person.2")
                                .font(.system(size: 48))
                                .foregroundColor(AppColors.separator)
                            Text("No users found")
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(itemViewModel.users) { user in
                                    AdminUserRow(user: user)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }
                }
                .background(AppColors.secondary)
                .navigationTitle("Users (\(itemViewModel.users.count))")
                .navigationBarTitleDisplayMode(.inline)
                .task {
                    await itemViewModel.fetchAllUsers()
                }
            }
        }

}


// MARK: - AdminUserRow

private struct AdminUserRow: View {

    // MARK: - Properties

    let user: UCUser

    private var avatarColor: Color {
        user.role == .admin ? AppColors.admin : AppColors.primary
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(avatarColor.opacity(0.15))
                    .frame(width: 46, height: 46)
                Text(String(user.name.prefix(2)).uppercased())
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(avatarColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(user.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    if user.role == .admin {
                        Text("ADMIN")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppColors.admin)
                            .cornerRadius(4)
                    }
                }
                Text(user.email)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
                Text(user.studentId)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()
        }
        .padding(14)
        .background(AppColors.card)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppColors.separator, lineWidth: 0.5)
        )
    }
}
