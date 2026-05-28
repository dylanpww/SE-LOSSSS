import SwiftUI

struct ItemDetailView: View {

    // MARK: - Properties

    @EnvironmentObject private var itemViewModel: ItemViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    let report: LostItemReport

    @State private var showClaimSheet: Bool = false
    @State private var showFoundSheet: Bool = false
    @State private var hasAlreadyClaimed: Bool = false

    private var isOwner: Bool {
        authViewModel.currentUser?.id == report.reporterId
    }

    private var itemClaims: [Claim] {
        itemViewModel.claims(for: report.id)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    photoSection
                    detailContent
                }
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Item Detail")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .task {
                guard let userId = authViewModel.currentUser?.id else { return }
                hasAlreadyClaimed = await itemViewModel.hasClaimed(
                    itemId: report.id,
                    userId: userId
                )
            }
            .sheet(isPresented: $showClaimSheet) {
                ClaimFormSheet(isPresented: $showClaimSheet, report: report)
                    .environmentObject(itemViewModel)
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showFoundSheet) {
                FoundFormSheet(isPresented: $showFoundSheet, report: report)
            }
        }
    }

    // MARK: - Private Sections

    private var detailContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            titleBlock
            Divider()
            metaBlock

            if isOwner && !itemClaims.isEmpty {
                claimsBlock
            }

            Spacer().frame(height: 12)

            if !isOwner {
                actionButton
            }
        }
        .padding(20)
    }
    
    private var photoSection: some View {
        Group {
            if let urlString = report.imageUrl,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 260)
                            .clipped()
                    case .failure:
                        PhotoPlaceholder()
                    case .empty:
                        PhotoPlaceholder()
                            .overlay(
                                ProgressView()
                                    .tint(.white)
                            )
                    @unknown default:
                        PhotoPlaceholder()
                    }
                }
            } else {
                PhotoPlaceholder()
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(report.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            StatusBadge(status: report.status)
        }
    }

    private var metaBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            DetailRow(
                icon: "mappin.circle.fill",
                label: "Location",
                value: report.location
            )
            DetailRow(
                icon: "calendar",
                label: report.status == .lost ? "Date Lost" : "Date Found",
                value: report.date.formatted(as: "dd MMM yyyy")
            )
            DetailRow(
                icon: "person.fill",
                label: "Reported by",
                value: report.reporterName
            )
            DetailRow(
                icon: "doc.text.fill",
                label: "Description",
                value: report.description
            )
        }
    }

    private var claimsBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
            SectionHeader(title: "Claims (\(itemClaims.count))")
            ForEach(itemClaims) { claim in
                OwnerClaimRow(claim: claim)
                    .environmentObject(itemViewModel)
            }
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if report.status == .lost {
            PrimaryButton(title: "I HAVE FOUND THIS") {
                showFoundSheet = true
            }
        } else {
            PrimaryButton(
                title: hasAlreadyClaimed ? "CLAIM SUBMITTED ✓" : "CLAIM"
            ) {
                if !hasAlreadyClaimed { showClaimSheet = true }
            }
            .opacity(hasAlreadyClaimed ? 0.55 : 1.0)
        }
    }
}


// MARK: - OwnerClaimRow

/// Claim row visible only to the report owner, with approve / reject controls.
private struct OwnerClaimRow: View {

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

            if claim.claimStatus == .pending {
                HStack(spacing: 8) {
                    approvalChip(title: "Approve", color: AppColors.found, status: .approved)
                    approvalChip(title: "Reject",  color: .red,            status: .rejected)
                }
            }
        }
        .padding(12)
        .background(AppColors.secondary)
        .cornerRadius(10)
    }

    private func approvalChip(
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


// MARK: - ClaimFormSheet

/// Modal sheet for submitting an ownership claim on a found item.
struct ClaimFormSheet: View {

    // MARK: - Properties

    @EnvironmentObject private var itemViewModel: ItemViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Binding var isPresented: Bool

    let report: LostItemReport

    @State private var message: String = ""
    @State private var submitted: Bool = false

    // MARK: - Body

    var body: some View {
        NavigationView {
            Group {
                if submitted {
                    SuccessOverlay(
                        message: "The reporter has been notified of your claim."
                    ) { isPresented = false }
                } else {
                    claimForm
                }
            }
            .navigationTitle("Claim Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

    private var claimForm: some View {
        VStack(spacing: 0) {
            Form {
                Section("Item") {
                    Text(report.title).font(.headline)
                    StatusBadge(status: report.status)
                }
                Section("Why do you believe this is yours?") {
                    TextEditor(text: $message)
                        .frame(height: 120)
                }
            }

            PrimaryButton(
                title: "Submit Claim",
                isLoading: itemViewModel.isLoading
            ) {
                submitClaim()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .opacity(message.isEmpty ? 0.6 : 1.0)
            .disabled(message.isEmpty)
        }
    }

    // MARK: - Private Helpers

    private func submitClaim() {
        guard let user = authViewModel.currentUser else { return }
        let claim = Claim(
            itemId: report.id,
            claimantId: user.id,
            claimantName: user.name,
            claimantEmail: user.email,
            message: message
        )
        Task {
            await itemViewModel.submitClaim(itemId: report.id, claim: claim)
            submitted = true
        }
    }
}


// MARK: - FoundFormSheet

/// Modal sheet shown when a user reports finding someone else's lost item.
struct FoundFormSheet: View {

    // MARK: - Properties

    @Binding var isPresented: Bool
    let report: LostItemReport

    @State private var foundLocation: String = ""
    @State private var submitted: Bool = false

    // MARK: - Body

    var body: some View {
        NavigationView {
            Group {
                if submitted {
                    SuccessOverlay(
                        message: "The owner has been notified you found their item."
                    ) { isPresented = false }
                } else {
                    Form {
                        Section("Item Found") {
                            Text(report.title).font(.headline)
                        }
                        Section("Where did you find it?") {
                            TextField("e.g. Library, 2nd Floor", text: $foundLocation)
                        }
                    }
                }
            }
            .navigationTitle("I Found This")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !submitted {
                        Button("Send") { submitted = true }
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
        }
    }
}
