import SwiftUI

// MARK: - ProfileView

/// Shows the current user's profile information, activity stats, and account settings.
/// No business logic — logout delegates to AuthViewModel.
struct ProfileView: View {

    // MARK: - Properties

    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var itemViewModel: ItemViewModel

    @State private var showLogoutConfirm: Bool = false

    private var user: UCUser? { authViewModel.currentUser }

    private var reportCount: Int {
        guard let id = user?.id else { return 0 }
        return itemViewModel.reports(for: id).count
    }

    private var claimCount: Int {
        guard let id = user?.id else { return 0 }
        return itemViewModel.claims.filter { $0.claimantId == id }.count
    }

    private var resolvedCount: Int {
        guard let id = user?.id else { return 0 }
        return itemViewModel.claims.filter {
            $0.claimantId == id && $0.claimStatus == .approved
        }.count
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    avatarHeader
                    statsRow
                    Spacer().frame(height: 20)
                    menuList
                    Spacer().frame(height: 20)
                    signOutButton
                    Spacer().frame(height: 100)
                }
            }
            .background(AppColors.secondary)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Sign Out", isPresented: $showLogoutConfirm) {
                Button("Sign Out", role: .destructive) { authViewModel.logout() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }

    // MARK: - Private Sections

    private var avatarHeader: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 20)

            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.15))
                    .frame(width: 90, height: 90)
                Text(avatarInitials)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(AppColors.primary)
            }

            VStack(spacing: 4) {
                Text(user?.name ?? "")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text(user?.email ?? "")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                Text(user?.studentId ?? "")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer().frame(height: 8)
        }
        .frame(maxWidth: .infinity)
        .background(AppColors.background)
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            ProfileStatCell(value: "\(reportCount)", label: "Reports")
            Divider().frame(height: 40)
            ProfileStatCell(value: "\(claimCount)", label: "Claims")
            Divider().frame(height: 40)
            ProfileStatCell(value: "\(resolvedCount)", label: "Resolved")
        }
        .padding(.vertical, 16)
        .background(AppColors.card)
        .overlay(
            Rectangle()
                .stroke(AppColors.separator, lineWidth: 0.5)
        )
    }

    private var menuList: some View {
        VStack(spacing: 0) {
            ProfileMenuItem(
                icon: "person.fill",
                title: "Edit Profile"
            ) {}
            Divider().padding(.leading, 52)
            ProfileMenuItem(
                icon: "bell.fill",
                title: "Notifications"
            ) {}
            Divider().padding(.leading, 52)
            ProfileMenuItem(
                icon: "shield.fill",
                title: "Privacy Settings"
            ) {}
            Divider().padding(.leading, 52)
            ProfileMenuItem(
                icon: "questionmark.circle.fill",
                title: "Help & Support"
            ) {}
            Divider().padding(.leading, 52)
            ProfileMenuItem(
                icon: "info.circle.fill",
                title: "About UC Lost & Found"
            ) {}
        }
        .background(AppColors.card)
        .cornerRadius(14)
        .padding(.horizontal, 16)
    }

    private var signOutButton: some View {
        Button(action: { showLogoutConfirm = true }) {
            HStack {
                Image(systemName: "arrow.right.square.fill")
                    .foregroundColor(.red)
                Text("Sign Out")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppColors.card)
            .cornerRadius(14)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Private Helpers

    private var avatarInitials: String {
        String((user?.name.prefix(2) ?? "UC").uppercased())
    }
}


// MARK: - ProfileStatCell

private struct ProfileStatCell: View {

    // MARK: - Properties

    let value: String
    let label: String

    // MARK: - Body

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}


// MARK: - ProfileMenuItem

private struct ProfileMenuItem: View {

    // MARK: - Properties

    let icon: String
    let title: String
    let action: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.primary)
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}
