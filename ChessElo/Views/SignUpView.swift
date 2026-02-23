import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var chessUsername = ""

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

    @State private var successMessage: String = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Account Details")) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .keyboardType(.emailAddress)

                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                }

                Section(header: Text("Chess.com Details")) {
                    TextField("Chess.com Username", text: $chessUsername)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }

                Button {
                    Task { await signUp() }
                } label: {
                    HStack {
                        if isLoading { ProgressView() }
                        Text(isLoading ? "Signing Up..." : "Sign Up")
                    }
                }
                .disabled(isLoading || !isValidInput)
            }
            .navigationTitle("Create Account")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .alert("Check your email", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text(successMessage)
        }
    }

    private var isValidInput: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        !chessUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func signUp() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            showError = false
        }

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedChess = chessUsername.trimmingCharacters(in: .whitespacesAndNewlines)

        let result = await authManager.signUp(
            email: trimmedEmail,
            password: password,
            chessUsername: trimmedChess
        )

        await MainActor.run {
            isLoading = false
            if result.ok {
                switch result.outcome {
                case .emailConfirmationSent:
                    successMessage = "We’ve sent a confirmation link to \(trimmedEmail). Verify it, then come back and sign in."
                    showSuccess = true

                case .signedIn:
                    // user is already signed in, dismiss immediately
                    dismiss()

                case .none:
                    successMessage = "Account created."
                    showSuccess = true
                }
            } else {
                errorMessage = "Sign up failed. Check details and try again."
                showError = true
            }
        }
    }
}
