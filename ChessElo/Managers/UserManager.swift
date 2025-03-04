import Foundation
import OSLog

private let logger = Logger(subsystem: "com.ReidApps.ChessElo", category: "UserManager")

@MainActor
class UserManager {
    static let shared = UserManager()
    
    private let defaults = UserDefaults.standard
    private let userKey = "currentUser"
    private let statsKey = "chessStats"
    
    private init() {}
    
    func signUp(email: String, password: String, chessUsername: String) throws -> User {
        logger.debug("Creating new user: \(email)")
        
        // Create new user
        let user = User(
            id: UUID().uuidString,
            email: email,
            chessUsername: chessUsername,
            createdAt: Date()
        )
        
        // Save user
        try saveUser(user)
        
        return user
    }
    
    func signIn(email: String, password: String) throws -> User {
        logger.debug("Signing in user: \(email)")
        
        guard let userData = defaults.data(forKey: userKey),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            throw AuthError.invalidCredentials
        }
        
        return user
    }
    

    func signOut() async throws {
        try await SupabaseManager.shared.supabase.auth.signOut()
    }
    
    func updateChessUsername(_ username: String) throws {
        guard var user = getCurrentUser() else {
            throw AuthError.notAuthenticated
        }
        
        user.chessUsername = username
        try saveUser(user)
    }
    
    func fetchStats(forUsername username: String) async throws -> ChessStats {
        // In a real app, this would fetch from Chess.com API
        // For now, return mock data
        return ChessStats(
            username: username,
            rapid: Int.random(in: 800...2000),
            blitz: Int.random(in: 800...2000),
            bullet: Int.random(in: 800...2000),
            lastUpdated: Date()
        )
    }
    
    // MARK: - Helper Methods
    
    private func saveUser(_ user: User) throws {
        let encoder = JSONEncoder()
        let userData = try encoder.encode(user)
        defaults.set(userData, forKey: userKey)
    }
    
    private func getCurrentUser() -> User? {
        guard let userData = defaults.data(forKey: userKey),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            return nil
        }
        return user
    }
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case notAuthenticated
    case userExists
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .notAuthenticated:
            return "User not authenticated"
        case .userExists:
            return "User already exists"
        }
    }
} 
