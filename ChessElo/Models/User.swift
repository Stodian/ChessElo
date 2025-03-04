import Foundation

struct User: Codable {
    let id: String
    var email: String
    var chessUsername: String?
    var createdAt: Date
}

struct ChessStats: Codable {
    let username: String
    var rapid: Int
    var blitz: Int
    var bullet: Int
    var lastUpdated: Date
} 