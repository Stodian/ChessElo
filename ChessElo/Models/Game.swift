import Foundation

struct Game: Identifiable {
    let id: UUID = UUID()
    let date: Date
    let opponentElo: Int
    let result: GameResult
    let eloChange: Int
    
    enum GameResult {
        case win
        case loss
        case draw
    }
} 
