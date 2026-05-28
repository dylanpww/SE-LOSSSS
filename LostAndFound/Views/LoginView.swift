import SwiftUI

struct LoginView: View {


    @EnvironmentObject private var authViewModel: AuthViewModel

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showRegister: Bool = false


    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                formSection
                footerSection
            }
        }
        .background(AppColors.background)
        .sheet(isPresented: $showRegister) {
            RegisterView()
                .environmentObject(authViewModel)
        }
    }


    private var headerSection: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)

            Image(systemName: "magnifyingglass.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(AppColors.primary)

            Text("UC Lost & Found")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Text("Sign in with your university email\nto report or find lost items")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 20)
        }
    }

    private var formSection: some View {
        VStack(spacing: 16) {
            FormField(
                label: "University Email",
                placeholder: "yourname@ciputra.ac.id",
                keyboardType: .emailAddress,
                text: $email
            )

            FormField(
                label: "Password",
                placeholder: "••••••••",
                isSecure: true,
                text: $password
            )

            if let msg = authViewModel.errorMessage {
                ErrorBanner(message: msg)
            }


            PrimaryButton(
                title: "Sign In",
                isLoading: authViewModel.isLoading
            ) {
                Task { await authViewModel.login(email: email, password: password) }
            }

            Button(action: { showRegister = true }) {
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .foregroundColor(AppColors.textSecondary)
                    Text("Register")
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.primary)
                }
                .font(.system(size: 14))
            }
        }
        .padding(.horizontal, 24)
    }


    private var footerSection: some View {
        Text("Only @ciputra.ac.id addresses are permitted")
            .font(.caption)
            .foregroundColor(AppColors.textSecondary)
            .multilineTextAlignment(.center)
            .padding(24)
    }
}
