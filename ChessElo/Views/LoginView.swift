import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthenticationManager

    @State private var email = ""
    @State private var password = ""

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showingSignUp = false

    var body: some View {
        ZStack {
            ChessboardBackground().ignoresSafeArea()
            Color.black.opacity(0.7).ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer().frame(height: 100)
                    .padding(.top, -50)

                VStack(spacing: 16) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white)

                    Text("CHESS ELO")
                        .font(.custom("Palatino-Bold", size: 36))
                        .foregroundColor(.white)
                }

                VStack(spacing: 20) {
                    TextField("", text: $email)
                        .textFieldStyle(.plain)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1)))
                        .foregroundColor(.white)
                        .placeholder(when: email.isEmpty) {
                            Text("Email")
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.leading, 18)
                        }

                    SecureField("", text: $password)
                        .textFieldStyle(.plain)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .textContentType(.password)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1)))
                        .foregroundColor(.white)
                        .placeholder(when: password.isEmpty) {
                            Text("Password")
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.leading, 18)
                        }
                }
                .padding(.horizontal)

                Button {
                    Task { await login() }
                } label: {
                    ZStack {
                        Text("Sign In")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.Maroon, .DarkMaroon]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .opacity(isLoading ? 0 : 1)

                        if isLoading {
                            ProgressView().tint(.white)
                        }
                    }
                }
                .disabled(isLoading || !isValidInput)
                .opacity(!isValidInput ? 0.6 : 1)
                .padding(.horizontal)

                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.gray)
                    Button("Sign Up") { showingSignUp = true }
                        .foregroundColor(.Maroon)
                }
                .font(.subheadline)
                .sheet(isPresented: $showingSignUp) {
                    SignUpView()
                        .environmentObject(authManager)
                }

                Spacer()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private var isValidInput: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty
    }

    private func login() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            showError = false
        }

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let ok = await authManager.signIn(email: trimmedEmail, password: password)

        await MainActor.run {
            isLoading = false
            if !ok {
                errorMessage = """
                Sign in failed.

                If you just signed up, confirm your email first, then try again.

                Otherwise, verify your email/password and try again.
                """
                showError = true
            }
        }
    }
}
