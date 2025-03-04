import SwiftUI

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var chessUsername = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account Details")) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                }
                
                Section(header: Text("Chess.com Details")) {
                    TextField("Chess.com Username", text: $chessUsername)
                        .autocapitalization(.none)
                }
                
                Button(action: {
                    isLoading = true
                    Task {
                        await signUp()
                    }
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Sign Up")
                    }
                }
                .disabled(isLoading || !isValidInput)
            }
            .navigationTitle("Create Account")
        }
        .alert("Error", isPresented: $showError, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(errorMessage ?? "An unknown error occurred")
        })
    }
    
    private var isValidInput: Bool {
        !email.isEmpty && !password.isEmpty && !chessUsername.isEmpty
    }
    
    private func signUp() async {
        do {
            // ✅ Step 1: Attempt Sign-Up
            let result = try await SupabaseManager.shared.supabase.auth.signUp(
                email: email,
                password: password
            )
            
            // ✅ Step 2: Get user ID and ensure it's a String
            let userId = result.user.id.uuidString
            print("✅ Successfully signed up with ID: \(userId)")
            
            // ✅ Step 3: Insert user into Supabase database
            try await SupabaseManager.shared.supabase
                .from("users")
                .insert([
                    "id": userId, // UUID converted to String
                    "email": email,
                    "chess_username": chessUsername
                ])
                .execute()
            
            print("✅ User data inserted into Supabase.")
            
            await MainActor.run {
                isLoading = false
                dismiss() // ✅ Close the sign-up screen after success
            }
            
        } catch {
            print("❌ Error during sign-up: \(error)")
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// ✅ Fixed #Preview - No Circular Reference
#Preview {
    SignUpView()
}
