import SwiftUI

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userName = ""
    @Published var chessUsername = ""
    @Published var isOnboardingComplete: Bool = UserDefaults.standard.bool(forKey: "onboardingCompleted") // ✅ Global onboarding state
    
    private let userManager = UserManager.shared
    private let supabaseManager = SupabaseManager.shared  // ✅ Use shared Supabase instance

    // ✅ Restore session on launch
    func restoreSession() async {
        do {
            let session = try? await supabaseManager.supabase.auth.session
            await MainActor.run {
                self.isAuthenticated = (session != nil)
            }
            print(session != nil ? "✅ Session restored" : "❌ No session found")
        } catch {
            print("❌ Error restoring session:", error.localizedDescription)
            await MainActor.run {
                self.isAuthenticated = false
            }
        }
    }
    
    
    // ✅ Mark onboarding as complete
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
        self.isOnboardingComplete = true
    }
    
    
    
    func signUp(email: String, password: String, chessUsername: String) async {
        do {
            let user = try userManager.signUp(email: email, password: password, chessUsername: chessUsername)
            updateAuthState(with: user)
        } catch {
            print("Signup error:", error.localizedDescription)
        }
    }
    
    func login(email: String, password: String) {
        do {
            let user = try userManager.signIn(email: email, password: password)
            updateAuthState(with: user)
        } catch {
            print("Login error:", error.localizedDescription)
        }
    }

    
    // 🔥 Fix: `logout()` now properly logs out from Supabase
    func logout() async {
        await supabaseManager.signOut() // ✅ Calls Supabase logout
        await MainActor.run {
            self.isAuthenticated = false
            self.userName = ""
            self.chessUsername = ""
        }
    }
    
    

    func updateUsername(_ newUsername: String) {
        do {
            try userManager.updateChessUsername(newUsername)
            chessUsername = newUsername
        } catch {
            print("Update username error:", error.localizedDescription)
        }
    }
    
    func refreshStats() async {
        guard !chessUsername.isEmpty else { return }
        do {
            let stats = try await userManager.fetchStats(forUsername: chessUsername)
            print("Stats updated:", stats)
        } catch {
            print("Refresh stats error:", error.localizedDescription)
        }
    }
    
    private func updateAuthState(with user: User) {
        isAuthenticated = true
        userName = user.email
        chessUsername = user.chessUsername ?? ""
    }
}
