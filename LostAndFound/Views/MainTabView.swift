import SwiftUI

// MARK: - MainTabView

/// Root navigation shell for student users.
/// Houses ItemBoardView, MyReportsView, ProfileView behind a custom tab bar
/// with a centre ADD LISTING call-to-action button.
struct MainTabView: View {

    // MARK: - Properties

    @State private var selectedTab: Int = 0
    @State private var showAddListing: Bool = false

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
            StudentTabBar(
                selectedTab: $selectedTab,
                showAddListing: $showAddListing
            )
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showAddListing) {
            AddListingView()
        }
    }

    // MARK: - Private Sections

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0:
            ItemBoardView(showAddListing: $showAddListing)
        case 1:
            MyReportsView()
        case 2:
            ProfileView()
        default:
            ItemBoardView(showAddListing: $showAddListing)
        }
    }
}


// MARK: - StudentTabBar

/// Custom bottom navigation bar matching the UC Lost & Found mockup design.
private struct StudentTabBar: View {

    // MARK: - Properties

    @Binding var selectedTab: Int
    @Binding var showAddListing: Bool

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            TabBarItem(
                icon: "house.fill",
                label: "HOME",
                isSelected: selectedTab == 0
            ) { selectedTab = 0 }

            TabBarItem(
                icon: "doc.text.fill",
                label: "REPORT",
                isSelected: selectedTab == 1
            ) { selectedTab = 1 }

            addListingButton

            TabBarItem(
                icon: "person.fill",
                label: "PROFILE",
                isSelected: selectedTab == 2
            ) { selectedTab = 2 }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(
            AppColors.card
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: -4)
        )
    }

    // MARK: - Private Sections

    /// Centre ADD LISTING call-to-action matching the design mockup.
    private var addListingButton: some View {
        Button(action: { showAddListing = true }) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.primary)
                        .frame(width: 60, height: 36)
                    Text("ADD\nLISTING")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}


// MARK: - TabBarItem

private struct TabBarItem: View {

    // MARK: - Properties

    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(
                        isSelected ? AppColors.primary : AppColors.textSecondary
                    )
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(
                        isSelected ? AppColors.primary : AppColors.textSecondary
                    )
            }
        }
        .frame(maxWidth: .infinity)
    }
}
