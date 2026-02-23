import Foundation
import Supabase

    @MainActor
    final class SupabaseManager {
        static let shared = SupabaseManager()

        // ✅ Add this
        static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN1amVqYmlla3ZqemVyeG5zbGNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE0Mzc1MTMsImV4cCI6MjA4NzAxMzUxM30.QMNwYUgQYG5-cRiiBdkUsm2Lz9N85d_1gpsp0PCA9zw" // your anon key

        let supabase: SupabaseClient
        static let authRedirectURL = URL(string: "chesselo://auth-callback")!

        private init() {
            self.supabase = SupabaseClient(
                supabaseURL: URL(string: "https://cujejbiekvjzerxnslcq.supabase.co")!,
                supabaseKey: Self.anonKey
            )
        }


    // Fresh install reset (prevents stale keychain sessions)
    func resetAuthIfFreshInstallIfNeeded() async {
        let key = "hasLaunchedBefore"
        guard UserDefaults.standard.bool(forKey: key) == false else { return }
        do { try await supabase.auth.signOut() } catch { }
        UserDefaults.standard.set(true, forKey: key)
    }

    // MARK: - Auth

    /// ✅ IMPORTANT: pass redirectTo so the email link returns into your app (chesselo://auth-callback)
    func signUp(email: String, password: String) async throws -> AuthResponse {
        return try await supabase.auth.signUp(
            email: email,
            password: password,
            redirectTo: Self.authRedirectURL
        )
    }

    func signIn(email: String, password: String) async throws {
        _ = try await supabase.auth.signIn(email: email, password: password)
    }

    func signOut() async {
        do { try await supabase.auth.signOut() }
        catch { print("❌ signOut failed:", String(reflecting: error)) }
    }

    // MARK: - Users table sync (UPSERT)

    private struct UserUpsertRow: Encodable {
        let id: String
        let email: String
        let display_name: String?
        let chess_username: String?
    }

    /// Ensures a row exists in `users` for the current authed user.
    /// - Uses UPSERT on primary key `id` so it never duplicates.
    /// - Will always keep `email` in sync from auth.
    /// - Will only write `chess_username` if a non-empty value is provided.
    /// - Will not overwrite `display_name` unless you pass one (currently nil).
    func ensureUserProfileRow(chessUsernameIfProvided: String? = nil) async throws {
        let session = try await supabase.auth.session
        let userId = session.user.id.uuidString
        let authEmail = session.user.email ?? ""

        let trimmedChess = chessUsernameIfProvided?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let chessToSave: String? = {
            guard let t = trimmedChess, !t.isEmpty else { return nil }
            return t
        }()

        let payload = UserUpsertRow(
            id: userId,
            email: authEmail,
            display_name: nil,
            chess_username: chessToSave
        )

        try await supabase
            .from("users")
            .upsert(payload, onConflict: "id")
            .execute()
    }
}
