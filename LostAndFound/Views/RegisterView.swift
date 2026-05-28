import SwiftUI

// MARK: - RegisterView

/// New account registration screen for UC students.
/// Accepts only @ciputra.ac.id email addresses (NFR-01).
/// No business logic — all validation and registration calls live in AuthViewModel.
struct RegisterView: View {

    // MARK: - Properties

    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var studentId: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var agreedToTerms: Bool = false

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    formSection
                    termsSection
                    actionSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .background(AppColors.background)
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.primary)
                }
            }
        }
    }

    // MARK: - Private Sections

    private var headerSection: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 8)

            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 32))
                    .foregroundColor(AppColors.primary)
            }

            Text("Join UC Lost & Found")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Text("Register with your university email\nto report and recover lost items")
                .font(.system(size: 13))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var formSection: some View {
        VStack(spacing: 14) {
            FormField(
                label: "Full Name",
                placeholder: "e.g. Alex Santoso",
                text: $fullName
            )
            FormField(
                label: "University Email",
                placeholder: "yourname@ciputra.ac.id",
                keyboardType: .emailAddress,
                text: $email
            )
            FormField(
                label: "Student ID",
                placeholder: "e.g. UC2021001",
                text: $studentId
            )
            FormField(
                label: "Password",
                placeholder: "Min. 8 characters",
                isSecure: true,
                text: $password
            )
            FormField(
                label: "Confirm Password",
                placeholder: "Re-enter your password",
                isSecure: true,
                text: $confirmPassword
            )

            if !password.isEmpty {
                PasswordStrengthIndicator(password: password)
            }

            if let msg = authViewModel.errorMessage {
                ErrorBanner(message: msg)
            }
        }
    }

    private var termsSection: some View {
        Button(action: { agreedToTerms.toggle() }) {
            HStack(alignment: .top, spacing: 10) {
                Image(
                    systemName: agreedToTerms
                        ? "checkmark.square.fill"
                        : "square"
                )
                .foregroundColor(
                    agreedToTerms ? AppColors.primary : AppColors.textSecondary
                )
                .font(.system(size: 18))

                Text(
                    "I agree that this account is for Universitas Ciputra use only "
                    + "and will not be shared with unauthorised parties."
                )
                .font(.system(size: 13))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.leading)
            }
        }
    }

    private var actionSection: some View {
        VStack(spacing: 12) {
            PrimaryButton(
                title: "Create Account",
                isLoading: authViewModel.isLoading
            ) {
                handleRegister()
            }
            .opacity(agreedToTerms ? 1.0 : 0.5)
            .disabled(!agreedToTerms)

            Button(action: { dismiss() }) {
                Text("Already have an account? Sign In")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.primary)
            }
        }
    }

    // MARK: - Private Helpers

    /// Builds a RegisterRequest and delegates to AuthViewModel.
    private func handleRegister() {
        guard agreedToTerms else {
            authViewModel.errorMessage =
                "Please agree to the terms before registering."
            return
        }
        let request = RegisterRequest(
            name: fullName,
            email: email,
            studentId: studentId,
            password: password,
            confirmPassword: confirmPassword
        )
        Task { await authViewModel.register(request: request) }
    }
}


// MARK: - PasswordStrengthIndicator

/// Visual strength meter shown while the user types their password.
private struct PasswordStrengthIndicator: View {

    // MARK: - Properties

    let password: String

    private var strengthScore: Int {
        var score = 0
        if password.meetsMinLength(8)  { score += 1 }
        if password.meetsMinLength(12) { score += 1 }
        if password.contains(where: { $0.isNumber }) { score += 1 }
        if password.contains(where: { !$0.isLetter && !$0.isNumber }) { score += 1 }
        return score
    }

    private var strengthLabel: String {
        switch strengthScore {
        case 0, 1: return "Weak"
        case 2:    return "Fair"
        case 3:    return "Good"
        default:   return "Strong"
        }
    }

    private var strengthColor: Color {
        switch strengthScore {
        case 0, 1: return .red
        case 2:    return AppColors.lost
        case 3:    return .yellow
        default:   return AppColors.found
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            index < strengthScore
                                ? strengthColor
                                : AppColors.separator
                        )
                        .frame(height: 4)
                }
            }
            Text("Password strength: \(strengthLabel)")
                .font(.caption)
                .foregroundColor(strengthColor)
        }
    }
}
