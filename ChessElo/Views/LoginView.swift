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
        NavigationStack {
            if authManager.isAuthenticated {
                ChessStatsView()  // ✅ Automatically navigates if user is logged in
            } else {
                loginContent
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
    
    private var loginContent: some View {
        ZStack {
            ChessboardBackground()
                .ignoresSafeArea()
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer().frame(height: 100)

                // App Title & Icon
                VStack(spacing: 16) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white)

                    Text("CHESS ELO")
                        .font(.custom("Palatino-Bold", size: 36))
                        .foregroundColor(.white)
                }

                // Input Fields
                VStack(spacing: 20) {
                    TextField("", text: $email)
                        .textFieldStyle(.plain)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                        )
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
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                        )
                        .foregroundColor(.white)
                        .placeholder(when: password.isEmpty) {
                            Text("Password")
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.leading, 18)
                        }
                }
                .padding(.horizontal)

                // Login Button
                Button(action: {
                    isLoading = true
                    errorMessage = nil
                    Task {
                        await login()
                    }
                }) {
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

                // Sign Up Prompt
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.gray)
                    Button("Sign Up") { showingSignUp = true }
                        .foregroundColor(.Maroon)
                }
                .font(.subheadline)
                .sheet(isPresented: $showingSignUp) { SignUpView() }

                Spacer()
            }
        }
        .alert("Error", isPresented: $showError, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(errorMessage ?? "An unknown error occurred")
        })
    }
    
    private var isValidInput: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    private func login() async {
        do {
            _ = try await SupabaseManager.shared.supabase.auth.signIn(
                email: email,
                password: password
            )
            
            await MainActor.run {
                authManager.isAuthenticated = true // ✅ Ensures persistent login
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}




#Preview {
    LoginView()
        .environmentObject(AuthenticationManager())
}
