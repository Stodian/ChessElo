import Supabase
import Foundation

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    @Published var chessUsername: String = "" // ✅ Store Chess.com username
    @Published var isAuthenticated: Bool = false // ✅ Track authentication state

    let supabase: SupabaseClient

    private init() {
        self.supabase = SupabaseClient(
            supabaseURL: URL(string: "https://nhqtwporuislmpomksyk.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ocXR3cG9ydWlzbG1wb21rc3lrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTAwMTA4MjcsImV4cCI6MjAyNTU4NjgyN30.0URwwRcvk9v9WZOI8Us0xJ-B5unyl2uQJRr8LqQU_Sg"
        )

        Task {
            await restoreSession() // ✅ Automatically restore session on launch
        }
    }

    // MARK: - 🔹 Restore Session on App Launch
    func restoreSession() async {
        do {
            let session = try await supabase.auth.session
            print("✅ Active session restored: \(session)")

            await MainActor.run {
                self.isAuthenticated = true
            }

            // 🔹 Fetch Chess.com username after restoring session
            await fetchChessUsername()

        } catch {
            print("❌ Failed to restore session: \(error.localizedDescription)")
            await MainActor.run {
                self.isAuthenticated = false
            }
        }
    }

    // MARK: - 🔹 Fetch Chess.com Username from Supabase
    func fetchChessUsername() async {
        do {
            // ✅ Ensure there is an authenticated user
            let session = try await supabase.auth.session
            let user = session.user

            print("🔍 Fetching Chess.com username for user ID: \(user.id)")

            // ✅ Corrected `.execute()` call to return actual data
            let response = try await supabase
                .from("users")
                .select("chess_username")
                .eq("id", value: user.id)
                .single()
                .execute()

            if let data = response.data as? [String: Any],
               let fetchedUsername = data["chess_username"] as? String {
                await MainActor.run {
                    self.chessUsername = fetchedUsername
                }
                print("✅ Chess.com username retrieved: \(fetchedUsername)")
            } else {
                print("❌ Chess.com username not found in Supabase")
            }

        } catch {
            print("❌ Error fetching Chess.com username: \(error.localizedDescription)")
        }
    }

    // MARK: - 🔹 User Sign In
    func signIn(email: String, password: String) async -> Bool {
        do {
            let session = try await supabase.auth.signIn(email: email, password: password)
            print("✅ User signed in successfully: \(session)")

            await MainActor.run {
                self.isAuthenticated = true
            }

            await fetchChessUsername() // ✅ Fetch username after login
            return true
        } catch {
            print("❌ Error signing in: \(error.localizedDescription)")
            await MainActor.run {
                self.isAuthenticated = false
            }
            return false
        }
    }

    // MARK: - 🔹 User Sign Up
    func signUp(email: String, password: String, chessUsername: String) async -> Bool {
        do {
            let result = try await supabase.auth.signUp(email: email, password: password)
            let userId = result.user.id.uuidString // ✅ Ensure UUID is converted to String

            // ✅ Save Chess.com username to Supabase
            try await supabase
                .from("users")
                .insert([
                    "id": userId,
                    "email": email,
                    "chess_username": chessUsername
                ])
                .execute()

            print("✅ User signed up & chess username saved")

            await MainActor.run {
                self.isAuthenticated = true
                self.chessUsername = chessUsername
            }
            return true
        } catch {
            print("❌ Error signing up: \(error.localizedDescription)")
            await MainActor.run {
                self.isAuthenticated = false
            }
            return false
        }
    }

    // MARK: - 🔹 Sign Out
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            print("✅ User signed out")
            await MainActor.run {
                self.isAuthenticated = false
                self.chessUsername = ""
            }
        } catch {
            print("❌ Error signing out: \(error.localizedDescription)")
        }
    }
}

