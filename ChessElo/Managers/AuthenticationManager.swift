import Foundation

@MainActor
final class AuthenticationManager: ObservableObject {

    @Published var isAuthenticated = false
    @Published var isRestoring = true

    @Published var email: String = ""
    @Published var displayName: String = ""
    @Published var chessUsername: String = ""
    @Published var chessAvatarURL: String = ""

    private let supabaseManager = SupabaseManager.shared
    private let pendingChessUsernameKey = "pendingChessUsername"

    enum SignupOutcome {
        case emailConfirmationSent
        case signedIn
    }

    init() {
        Task { await restoreSession() }
    }

    // MARK: - Restore session
    func restoreSession() async {
        isRestoring = true
        defer { isRestoring = false }

        do {
            await supabaseManager.resetAuthIfFreshInstallIfNeeded()
            _ = try await supabaseManager.supabase.auth.refreshSession()

            // session exists -> ensure users row exists, apply pending chess username
            try await applyPendingChessUsernameIfAny()

            // Enforce must exist in users table
            try await validateUserRowExists()

            isAuthenticated = true
            await fetchUserInfo()

        } catch {
            await supabaseManager.signOut()
            clearLocalState()
            isAuthenticated = false
        }
    }

    // MARK: - Enforce users row exists
    private func validateUserRowExists() async throws {
        let session = try await supabaseManager.supabase.auth.session
        let userId = session.user.id.uuidString

        struct ExistsRow: Decodable { let id: String }

        _ = try await supabaseManager.supabase
            .from("users")
            .select("id")
            .eq("id", value: userId)
            .single()
            .execute()
            .value as ExistsRow
    }

    // MARK: - Profile fetch
    struct UserProfile: Decodable {
        let email: String?
        let display_name: String?
        let chess_username: String?
    }

    private func fetchUserInfo() async {
        do {
            let session = try await supabaseManager.supabase.auth.session
            let userId = session.user.id.uuidString

            let profile: UserProfile = try await supabaseManager.supabase
                .from("users")
                .select("email, display_name, chess_username")
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            let authEmail = session.user.email ?? ""
            email = !authEmail.isEmpty ? authEmail : (profile.email ?? "")
            displayName = profile.display_name ?? ""
            chessUsername = profile.chess_username ?? ""

            // Chess.com avatar (best-effort)
            let u = chessUsername.trimmingCharacters(in: .whitespacesAndNewlines)
            if !u.isEmpty {
                do {
                    let chessProfile = try await ChessAPI.fetchPlayerProfile(for: u)
                    chessAvatarURL = chessProfile.avatar ?? ""
                } catch {
                    chessAvatarURL = ""
                }
            } else {
                chessAvatarURL = ""
            }
        } catch {
            // optional logging
        }
    }

    /// Used by AccountDetailsView after saving to refresh avatar + latest values
    func refreshProfile() async {
        await fetchUserInfo()
    }

    // MARK: - Sign In
    @discardableResult
    func signIn(email: String, password: String) async -> Bool {
        do {
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

            try await supabaseManager.signIn(email: trimmedEmail, password: password)

            // now session exists -> ensure row, apply pending chess username
            try await applyPendingChessUsernameIfAny()

            // enforce must exist in users table
            try await validateUserRowExists()

            isAuthenticated = true
            await fetchUserInfo()
            return true

        } catch {
            print("❌ signIn error:", String(reflecting: error))
            isAuthenticated = false
            return false
        }
    }

    // MARK: - Sign Up
    /// With email confirmations ON, this returns `.emailConfirmationSent`
    func signUp(email: String, password: String, chessUsername: String) async -> (ok: Bool, outcome: SignupOutcome?) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedChess = chessUsername.trimmingCharacters(in: .whitespacesAndNewlines)

        // store until we can write to users table
        UserDefaults.standard.set(trimmedChess, forKey: pendingChessUsernameKey)
        self.chessUsername = trimmedChess

        do {
            let response = try await supabaseManager.signUp(email: trimmedEmail, password: password)

            // ✅ CASE A: Email confirmation ON -> no session yet
            if response.session == nil {
                isAuthenticated = false
                return (true, .emailConfirmationSent)
            }

            // ✅ CASE B: Email confirmation OFF -> user is already signed in
            try await applyPendingChessUsernameIfAny()     // creates users row + saves chess username
            try await validateUserRowExists()

            isAuthenticated = true
            await fetchUserInfo()
            return (true, .signedIn)

        } catch {
            print("❌ signUp error:", String(reflecting: error))
            return (false, nil)
        }
    }

    // MARK: - Logout
    func logout() async {
        await supabaseManager.signOut()
        isAuthenticated = false
        clearLocalState()
    }

    private func clearLocalState() {
        email = ""
        displayName = ""
        chessUsername = ""
        chessAvatarURL = ""
    }

    // MARK: - Helpers
    private func applyPendingChessUsernameIfAny() async throws {
        let pendingChess = UserDefaults.standard.string(forKey: pendingChessUsernameKey)

        try await supabaseManager.ensureUserProfileRow(chessUsernameIfProvided: pendingChess)

        if pendingChess != nil {
            UserDefaults.standard.removeObject(forKey: pendingChessUsernameKey)
        }
    }
}
