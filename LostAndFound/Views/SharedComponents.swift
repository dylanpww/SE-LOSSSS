import SwiftUI

struct StatusBadge: View {
    let status: ItemStatus
    
    private var badgeColor: Color {
            switch status {
            case .lost:    return AppColors.lost
            case .found:   return AppColors.found
            case .claimed: return AppColors.admin
            }
        }

    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(badgeColor)
            .cornerRadius(6)
    }
}



struct ClaimStatusBadge: View {
    let claimStatus: ClaimStatus

    private var badgeColor: Color {
        switch claimStatus {
        case .pending:  return AppColors.lost
        case .approved: return AppColors.found
        case .rejected: return .red
        }
    }

    // MARK: - Body

    var body: some View {
        Text(claimStatus.rawValue.uppercased())
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(badgeColor)
            .cornerRadius(6)
    }
}

struct PrimaryButton: View {

    let title: String
    var isLoading: Bool = false
    let action: () -> Void


    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppColors.primary)
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }
}


// MARK: - FormField

/// Labelled text or secure input field for form screens.
struct FormField: View {

    // MARK: - Properties

    let label: String
    let placeholder: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    @Binding var text: String

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .autocapitalization(
                            keyboardType == .emailAddress ? .none : .words
                        )
                }
            }
            .padding(14)
            .background(AppColors.secondary)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppColors.separator, lineWidth: 0.5)
            )
        }
    }
}


// MARK: - ErrorBanner

/// Inline error message shown below form fields.
struct ErrorBanner: View {

    // MARK: - Properties

    let message: String

    // MARK: - Body

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.caption)
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}


// MARK: - ItemCard

/// List row card summarising a single LostItemReport.
struct ItemCard: View {

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
            .frame(width: 72, height: 72)
            .cornerRadius(10)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(report.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)

                Text(report.location)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)

                StatusBadge(status: report.status)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(14)
        .background(AppColors.card)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppColors.separator, lineWidth: 0.5)
        )
    }}


// MARK: - FilterChip

/// Toggleable pill button for filtering the item board.
struct FilterChip: View {

    // MARK: - Properties

    let title: String
    let isSelected: Bool
    let action: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(
                    isSelected ? AppColors.textPrimary : AppColors.textSecondary
                )
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isSelected ? AppColors.card : Color.clear)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? AppColors.separator : Color.clear,
                            lineWidth: 0.5
                        )
                )
        }
    }
}


// MARK: - DetailRow

/// Icon + label + value row used inside ItemDetailView.
struct DetailRow: View {

    // MARK: - Properties

    let icon: String
    let label: String
    let value: String

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppColors.primary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
                Text(value)
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textPrimary)
            }
        }
    }
}


// MARK: - SuccessOverlay

/// Full-screen success state shown after an action completes.
struct SuccessOverlay: View {

    // MARK: - Properties

    let message: String
    let onDone: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(AppColors.found)

            Text("Success!")
                .font(.title)
                .fontWeight(.bold)

            Text(message)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            PrimaryButton(title: "Done", action: onDone)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
        }
    }
}


struct PhotoPlaceholder: View {

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(hex: "7D7168"))
                .frame(height: 260)

            VStack(spacing: 8) {
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.7))
                Text("FOTO")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}


// MARK: - SectionHeader

/// Bold section label used inside scroll views.
struct SectionHeader: View {

    // MARK: - Properties

    let title: String

    // MARK: - Body

    var body: some View {
        Text(title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(AppColors.textPrimary)
    }
}
