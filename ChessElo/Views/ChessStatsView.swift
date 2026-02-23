import SwiftUI
import WidgetKit
import Charts
import UIKit
import Foundation

enum SharedDefaults {
    static let groupID = "group.com.stodian.chesselo"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)
    }

    static var available: Bool {
        containerURL != nil
    }

    /// NEVER call suiteName unless container exists
    private static func suite() -> UserDefaults? {
        guard available else { return nil }
        return UserDefaults(suiteName: groupID)
    }

    static func set(_ value: Any?, forKey key: String) {
        guard let ud = suite() else { return }
        ud.set(value, forKey: key)
    }

    static func int(_ key: String) -> Int? {
        guard let ud = suite() else { return nil }
        return ud.integer(forKey: key)
    }

    static func string(_ key: String) -> String? {
        guard let ud = suite() else { return nil }
        return ud.string(forKey: key)
    }
}

// MARK: - ChessStatsView
struct ChessStatsView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    @State private var stats: ChessAPI.ChessStats?
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showMoreStats = false

    // Cache key
    private let cachedStatsKey = "cachedChessStats_v1"

    // Codable cache model
    private struct CachedChessStats: Codable {
        let username: String
        let avatar: String?
        let countryCode: String
        let blitzRating: Int
        let bulletRating: Int
        let rapidRating: Int
        let dailyRating: Int
        let chess960Rating: Int
        let tacticsRating: Int
        let lessonsCompleted: Int
        let tournamentsPlayed: Int
        let matchesWon: Int
        let winRate: Double
        let puzzleRushBest: Int
        let cachedAt: Date
    }

    private func loadCachedStatsIfAny() {
        guard stats == nil else { return }
        guard SharedDefaults.available else { return }
        guard let json = SharedDefaults.string(cachedStatsKey),
              let data = json.data(using: .utf8),
              let cached = try? JSONDecoder().decode(CachedChessStats.self, from: data)
        else { return }

        stats = ChessAPI.ChessStats(
            username: cached.username,
            avatar: cached.avatar,
            countryCode: cached.countryCode,
            blitzRating: cached.blitzRating,
            bulletRating: cached.bulletRating,
            rapidRating: cached.rapidRating,
            dailyRating: cached.dailyRating,
            chess960Rating: cached.chess960Rating,
            tacticsRating: cached.tacticsRating,
            lessonsCompleted: cached.lessonsCompleted,
            tournamentsPlayed: cached.tournamentsPlayed,
            matchesWon: cached.matchesWon,
            winRate: cached.winRate,
            puzzleRushBest: cached.puzzleRushBest
        )
    }

    private func saveCachedStats(_ s: ChessAPI.ChessStats) {
        guard SharedDefaults.available else { return }
        let cached = CachedChessStats(
            username: s.username,
            avatar: s.avatar,
            countryCode: s.countryCode,
            blitzRating: s.blitzRating,
            bulletRating: s.bulletRating,
            rapidRating: s.rapidRating,
            dailyRating: s.dailyRating,
            chess960Rating: s.chess960Rating,
            tacticsRating: s.tacticsRating,
            lessonsCompleted: s.lessonsCompleted,
            tournamentsPlayed: s.tournamentsPlayed,
            matchesWon: s.matchesWon,
            winRate: s.winRate,
            puzzleRushBest: s.puzzleRushBest,
            cachedAt: Date()
        )

        if let data = try? JSONEncoder().encode(cached),
           let json = String(data: data, encoding: .utf8) {
            SharedDefaults.set(json, forKey: cachedStatsKey)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ChessboardBackground().ignoresSafeArea()
                Color.black.opacity(0.7).ignoresSafeArea()

                VStack(spacing: 15) {
                    Spacer(minLength: -40)

                    header

                    Spacer()

                    if let stats = stats {
                        statsBlock(stats)

                        moreButton

                        if showMoreStats {
                            moreStatsBlock(stats)
                        }

                        WidgetCardView(title: "Chess Quote") {
                            ChessQuoteWidgetView()
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 40)

                        Spacer(minLength: 50)
                    } else {
                        Text(errorMessage?.isEmpty == false ? errorMessage! : "Loading stats...")
                            .foregroundColor(.white.opacity(0.75))
                            .padding()
                    }
                }
                .padding(.top, 15)
                .padding()
            }
            .navigationBarHidden(true)
        }
        .onAppear { loadCachedStatsIfAny() }
        .task(id: authManager.chessUsername) {
            await refreshStats()
        }
    }

    private var header: some View {
        HStack {
            NavigationLink {
                Leaderboard().environmentObject(authManager)
            } label: {
                Image(systemName: "person.2.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.white)
                    .padding(.leading, 20)
            }

            Spacer()

            VStack(spacing: 6) {
                Text("ChessElo")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)

            }

            Spacer()

            NavigationLink(destination: SettingsView()) {
                Image(systemName: "gearshape")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
                    .padding(.trailing, 20)
            }
        }
        .padding(.top, 20)
        .frame(maxWidth: .infinity)
    }

    private func statsBlock(_ stats: ChessAPI.ChessStats) -> some View {
        VStack(spacing: 20) {
            if let avatar = stats.avatar, let url = URL(string: avatar) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                } placeholder: {
                    ProgressView().tint(.white)
                }
            }

            Text(stats.username)
                .font(.title)
                .bold()
                .foregroundColor(.white)

            Text("📍 Country: \(stats.countryCode)")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))

            Divider().background(Color.white).padding(.horizontal)

            VStack(spacing: 12) {
                ChessStatRow(title: "♟️ Blitz Rating", value: "\(stats.blitzRating)")
                ChessStatRow(title: "⚡ Bullet Rating", value: "\(stats.bulletRating)")
                ChessStatRow(title: "⏳ Rapid Rating", value: "\(stats.rapidRating)")
            }
        }
        .padding(.horizontal, 15)
    }

    private var moreButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showMoreStats.toggle()
            }
        } label: {
            Image(systemName: "chevron.down")
                .rotationEffect(.degrees(showMoreStats ? 180 : 0))
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 15)
        }
    }

    private func moreStatsBlock(_ stats: ChessAPI.ChessStats) -> some View {
        VStack(spacing: 8) {
            ChessStatRow(title: "🛡️ Daily Chess Rating", value: "\(stats.dailyRating)")
            ChessStatRow(title: "♜ Chess960 Rating", value: "\(stats.chess960Rating)")
            ChessStatRow(title: "🧩 Puzzle Rating", value: "\(stats.tacticsRating)")
            ChessStatRow(title: "🎓 Lessons Completed", value: "\(stats.lessonsCompleted)")
            ChessStatRow(title: "🏆 Tournaments Played", value: "\(stats.tournamentsPlayed)")
            ChessStatRow(title: "⚔️ Matches Won", value: "\(stats.matchesWon)")
            ChessStatRow(title: "📊 Win Rate", value: "\(String(format: "%.2f", stats.winRate))%")
            ChessStatRow(title: "🔥 Puzzle Rush Score", value: "\(stats.puzzleRushBest)")
        }
        .transition(.opacity.combined(with: .scale))
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    // MARK: - Supabase Upsert
    private struct UserChessStatsUpsert: Encodable {
        let user_id: String
        let chess_country_code: String?
        let chess_avatar_url: String?

        let blitz_rating: Int?
        let bullet_rating: Int?
        let rapid_rating: Int?
        let daily_rating: Int?
        let chess960_rating: Int?
        let tactics_rating: Int?
        let lessons_completed: Int?
        let tournaments_played: Int?
        let matches_won: Int?
        let win_rate: Double?
        let puzzle_rush_best: Int?

        // ✅ NEW
        let last_game_played_at: String?

        let stats_last_synced_at: String
        let updated_at: String
    }

    private func upsertUserChessStats(
        userId: String,
        stats: ChessAPI.ChessStats,
        lastGameISO: String?
    ) async throws {
        let now = ISO8601DateFormatter().string(from: Date())

        let payload = UserChessStatsUpsert(
            user_id: userId,
            chess_country_code: stats.countryCode,
            chess_avatar_url: stats.avatar,
            blitz_rating: stats.blitzRating,
            bullet_rating: stats.bulletRating,
            rapid_rating: stats.rapidRating,
            daily_rating: stats.dailyRating,
            chess960_rating: stats.chess960Rating,
            tactics_rating: stats.tacticsRating,
            lessons_completed: stats.lessonsCompleted,
            tournaments_played: stats.tournamentsPlayed,
            matches_won: stats.matchesWon,
            win_rate: stats.winRate,
            puzzle_rush_best: stats.puzzleRushBest,
            last_game_played_at: lastGameISO,
            stats_last_synced_at: now,
            updated_at: now
        )

        try await SupabaseManager.shared.supabase
            .from("user_chess_stats")
            .upsert(payload, onConflict: "user_id")
            .execute()
    }

    // MARK: - Refresh
    @MainActor
    private func refreshStats() async {
        let username = authManager.chessUsername.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !username.isEmpty else {
            if stats == nil { errorMessage = "No Chess.com username set." }
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetchedStats = try await ChessAPI.fetchStats(for: username)

            // ✅ get last game date from Chess.com
            let lastGameDate = try await ChessAPI.fetchLastGamePlayedAt(for: username)
            let iso = ISO8601DateFormatter()
            let lastGameISO = lastGameDate.map { iso.string(from: $0) }

            // update + cache
            stats = fetchedStats
            saveCachedStats(fetchedStats)

            // upsert to Supabase
            let session = try await SupabaseManager.shared.supabase.auth.session
            try await upsertUserChessStats(
                userId: session.user.id.uuidString,
                stats: fetchedStats,
                lastGameISO: lastGameISO
            )

            // widgets
            if SharedDefaults.available {
                SharedDefaults.set(fetchedStats.blitzRating, forKey: "blitzRating")
                SharedDefaults.set(fetchedStats.bulletRating, forKey: "bulletRating")
                SharedDefaults.set(fetchedStats.rapidRating, forKey: "rapidRating")
            }
            WidgetCenter.shared.reloadAllTimelines()

        } catch is CancellationError {
            return
        } catch let urlError as URLError where urlError.code == .cancelled {
            return
        } catch {
            errorMessage = "Error fetching chess stats: \(error.localizedDescription)"
        }
    }

    // MARK: - Quote view (1 minute timer, no stacking)
    struct ChessQuoteWidgetView: View {
        @State private var currentQuoteIndex = 0
        @State private var timer: Timer?
        private let quotes: [(quote: String, author: String)] = [
            ("Chess is the struggle against one’s own errors.", "Savielly Tartakower"),
            ("When you see a good move, look for a better one.", "Emanuel Lasker"),
            ("Every chess master was once a beginner.", "Irving Chernev"),
            ("The beauty of a move lies in the thought behind it.", "Siegbert Tarrasch"),
            ("Even a poor plan is better than no plan at all.", "Mikhail Chigorin"),
            ("You may learn much more from a game you lose than from a game you win.", "José Raúl Capablanca"),
            ("In life, as in chess, forethought wins.", "Charles Buxton"),
            ("Tactics flow from a superior position.", "Bobby Fischer"),
            ("Chess is mental torture.", "Garry Kasparov"),
            ("The hardest game to win is a won game.", "Emanuel Lasker"),
            ("A sacrifice is best refuted by accepting it.", "Wilhelm Steinitz"),
            ("To play for a draw, at any rate with white, is to some degree a crime against chess.", "Mikhail Tal"),
            ("The pin is mightier than the sword.", "Fred Reinfeld"),
            ("Give me a difficult positional game, I will play it. But totally won positions, I cannot stand them.", "Hein Donner"),
            ("Many have become chess masters; no one has become the master of chess.", "Siegbert Tarrasch"),
            ("Chess is a war over the board. The object is to crush the opponent’s mind.", "Bobby Fischer"),
            ("Avoid the crowd. Do your own thinking independently. Be the chess player, not the chess piece.", "Ralph Charell"),
            ("The blunders are all there on the board, waiting to be made.", "Savielly Tartakower"),
            ("The threat is stronger than the execution.", "Aron Nimzowitsch"),
            ("Help your pieces so they can help you.", "Paul Morphy"),
            ("Chess is a sea in which a gnat may drink and an elephant may bathe.", "Indian Proverb"),
            ("I don’t believe in psychology. I believe in good moves.", "Bobby Fischer"),
            ("To avoid losing a piece, many a person has lost the game.", "Savielly Tartakower"),
            ("It is not a move, even the best move, that you must seek, but a realizable plan.", "Eugene Znosko-Borovsky"),
            ("One doesn’t have to play well, it’s enough to play better than your opponent.", "Siegbert Tarrasch"),
            ("There is no remorse like the remorse of chess.", "H.G. Wells"),
            ("Sometimes the best move is no move at all.", "Svetozar Gligorić"),
            ("Pawns are the soul of chess.", "Philidor"),
            ("The winner is the one who makes the next-to-last mistake.", "Savielly Tartakower"),
            ("If you see a good move, look for a better one.", "Emanuel Lasker"),
            ("A passed pawn increases in strength as the number of pieces on the board diminishes.", "Capablanca"),
            ("A knight on the rim is dim.", "Chess Proverb"),
            ("One bad move nullifies forty good ones.", "Bernhard Horwitz"),
            ("There is no room for uncertainty in chess.", "Mikhail Botvinnik"),
            ("Every chess player should have a plan.", "Mikhail Chigorin"),
            ("Chess is everything: art, science, and sport.", "Anatoly Karpov"),
            ("Even a dead piece can sometimes have the last word.", "Bent Larsen"),
            ("To play for a draw is to play with fire.", "Tigran Petrosian"),
            ("If your opponent offers you a draw, try to work out why he thinks he’s worse off.", "Nigel Short"),
            ("Good players know when to calculate and when to trust their intuition.", "Vladimir Kramnik"),
            ("The ability to work hard for days, for weeks, for years, to be patient, to never lose hope, to always be ready to start again, is the skill that distinguishes the master from the amateur.", "Garry Kasparov"),
            ("A well-developed knight on the sixth rank can be more powerful than a rook.", "Aron Nimzowitsch"),
            ("Attackers may sometimes regret leaving themselves open, but defenders always regret not attacking.", "Garry Kasparov"),
            ("A sacrifice is the test of the player’s skill.", "Rudolf Spielmann"),
            ("Control the center and you control the game.", "Wilhelm Steinitz"),
            ("An isolated pawn is like a lone warrior without backup.", "Vassily Ivanchuk"),
            ("Before you make a move, sit on your hands.", "Tigran Petrosian"),
            ("There is no greater agony than knowing you had the winning move and missed it.", "Garry Kasparov"),
            ("A player’s first duty is to be always alert, never to let his guard down.", "Alexander Alekhine"),
            ("When you defend, you must defend actively, never passively.", "Bobby Fischer"),
            ("A bad plan is better than no plan at all.", "Frank Marshall"),
            ("Chess teaches patience, calculation, and the ability to think before acting.", "Judit Polgar"),
            ("You have to have the fighting spirit. You have to force moves and take chances.", "Bobby Fischer"),
            ("Only the player with the initiative has the right to attack.", "Wilhelm Steinitz"),
            ("The most important thing in chess is confidence. The second most important thing is confidence.", "Viktor Korchnoi"),
            ("Sometimes a pawn breakthrough is worth a piece.", "Mikhail Tal"),
            ("Whoever sees no advantage in the position should resign immediately.", "Vladimir Kramnik"),
            ("To improve at chess, you must study the endgame before everything else.", "José Raúl Capablanca"),
            ("If you cannot see the right move, find another way to make progress.", "Garry Kasparov"),
            ("The stronger the players, the greater the importance of strategy over tactics.", "Tigran Petrosian"),
            ("Never be afraid to sacrifice a pawn if it helps your overall strategy.", "Anatoly Karpov"),
            ("Don’t get caught in the illusion that playing too fast is better than playing too slow.", "Magnus Carlsen"),
            ("The key to a good chess game is to play the position, not the opponent.", "Mikhail Botvinnik"),
            ("Chess is 99% tactics, but you won’t see them if you don’t understand strategy.", "Siegbert Tarrasch"),
            ("Your mind is your best piece.", "Bobby Fischer"),
            ("Never assume that just because a move looks bad, it is bad.", "Mikhail Tal"),
            ("Endgame knowledge is what separates a master from an amateur.", "José Raúl Capablanca"),
            ("All great players understand that chess is more than just moving pieces—it's a battle of ideas.", "Garry Kasparov")
        ]
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("♟ Quotes")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))

                Divider().background(Color.white.opacity(0.3))

                VStack(alignment: .leading, spacing: 10) {
                    Text("“\(quotes[currentQuoteIndex].quote)”")
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .italic()
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)

                    Text("- \(quotes[currentQuoteIndex].author)")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .frame(width: 320, height: 180)
            .background(VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1)))
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            .onAppear {
                timer?.invalidate()
                timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentQuoteIndex = (currentQuoteIndex + 1) % quotes.count
                    }
                }
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
    }

    // MARK: - VisualEffectBlur
    struct VisualEffectBlur: UIViewRepresentable {
        var blurStyle: UIBlurEffect.Style
        func makeUIView(context: Context) -> UIVisualEffectView {
            UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        }
        func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
    }

    // MARK: - WidgetCardView
    struct WidgetCardView<Content: View>: View {
        let title: String
        @ViewBuilder let content: () -> Content

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                content()
                    .padding()
                    .background(VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1)))
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                    .frame(height: 110)
            }
        }
    }
}

// MARK: - ExampleWidget Component
struct ExampleWidget: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

// MARK: - ChessStatRow Component
struct ChessStatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
    }
}

// MARK: - ChessAPI
struct ChessAPI {

    struct ChessStats {
        let username: String
        let avatar: String?
        let countryCode: String
        let blitzRating: Int
        let bulletRating: Int
        let rapidRating: Int
        let dailyRating: Int
        let chess960Rating: Int
        let tacticsRating: Int
        let lessonsCompleted: Int
        let tournamentsPlayed: Int
        let matchesWon: Int
        let winRate: Double
        let puzzleRushBest: Int
    }

    // MARK: - Endpoint 1: Player Profile
    static func fetchPlayerProfile(for username: String) async throws -> ChessProfileResponse {
        let url = URL(string: "https://api.chess.com/pub/player/\(username)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ChessProfileResponse.self, from: data)
    }

    // MARK: - Endpoint 2: Player Stats
    static func fetchPlayerStats(for username: String) async throws -> ChessStatsResponse {
        let url = URL(string: "https://api.chess.com/pub/player/\(username)/stats")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ChessStatsResponse.self, from: data)
    }

    // MARK: - Combined: Stats + Profile
    static func fetchStats(for username: String) async throws -> ChessStats {
        async let statsResponse = fetchPlayerStats(for: username)
        async let profileResponse = fetchPlayerProfile(for: username)

        let stats = try await statsResponse
        let profile = try await profileResponse

        return ChessStats(
            username: profile.username ?? "Unknown",
            avatar: profile.avatar,
            countryCode: profile.countryCode,
            blitzRating: stats.chessBlitz?.last?.rating ?? 0,
            bulletRating: stats.chessBullet?.last?.rating ?? 0,
            rapidRating: stats.chessRapid?.last?.rating ?? 0,
            dailyRating: stats.chessDaily?.last?.rating ?? 0,
            chess960Rating: stats.chess960Daily?.last?.rating ?? 0,
            tacticsRating: stats.tactics?.highest?.rating ?? 0,
            lessonsCompleted: stats.lessons?.highest?.rating ?? 0,
            tournamentsPlayed: stats.tournamentsPlayed ?? 0,
            matchesWon: stats.matchesWon ?? 0,
            winRate: stats.winRate,
            puzzleRushBest: stats.puzzleRush?.best?.score ?? 0
        )
    }

    // MARK: - Endpoint 3: Player Game Archives
    static func fetchArchives(for username: String) async throws -> ArchivesResponse {
        let url = URL(string: "https://api.chess.com/pub/player/\(username)/games/archives")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(ArchivesResponse.self, from: data)
    }

    // MARK: - Endpoint 4: Monthly Games
    static func fetchGames(for username: String, year: Int, month: Int) async throws -> GamesResponse {
        let monthString = String(format: "%02d", month)
        let url = URL(string: "https://api.chess.com/pub/player/\(username)/games/\(year)/\(monthString)")!
        let (data, _) = try await URLSession.shared.data(from: url)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase   // ✅ important for end_time -> endTime
        return try decoder.decode(GamesResponse.self, from: data)
    }

    // ✅ NEW: Get last game played date (uses archives -> newest month -> max endTime)
    static func fetchLastGamePlayedAt(for username: String) async throws -> Date? {
        let archives = try await fetchArchives(for: username)

        // newest first
        let newestFirst = archives.archives.reversed()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        for urlString in newestFirst.prefix(6) { // try last 6 months
            guard let url = URL(string: urlString) else { continue }
            let (data, _) = try await URLSession.shared.data(from: url)
            let month = try decoder.decode(GamesResponse.self, from: data)

            if let maxEnd = month.games.compactMap(\.endTime).max() {
                return Date(timeIntervalSince1970: TimeInterval(maxEnd))
            }
        }

        return nil
    }

    // MARK: - Endpoint 5: Tournament Information
    static func fetchTournament(for tournamentId: String) async throws -> TournamentResponse {
        let url = URL(string: "https://api.chess.com/pub/tournament/\(tournamentId)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(TournamentResponse.self, from: data)
    }

    // MARK: - Endpoint 6: Leaderboards
    static func fetchLeaderboards() async throws -> LeaderboardsResponse {
        let url = URL(string: "https://api.chess.com/pub/leaderboards")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(LeaderboardsResponse.self, from: data)
    }

    // MARK: - Endpoint 7: Club Information
    static func fetchClub(for clubId: String) async throws -> ClubResponse {
        let url = URL(string: "https://api.chess.com/pub/club/\(clubId)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ClubResponse.self, from: data)
    }

    // MARK: - Endpoint 8: Daily Puzzle
    static func fetchDailyPuzzle() async throws -> PuzzleResponse {
        let url = URL(string: "https://api.chess.com/pub/puzzle")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(PuzzleResponse.self, from: data)
    }
}

// MARK: - API Response Models

struct ChessProfileResponse: Codable {
    let username: String?
    let avatar: String?
    let country: String?

    var countryCode: String {
        country?.components(separatedBy: "/").last ?? "Unknown"
    }
}

struct ChessStatsResponse: Codable {
    let chessBlitz: ChessGameStats?
    let chessBullet: ChessGameStats?
    let chessRapid: ChessGameStats?
    let chessDaily: ChessGameStats?
    let chess960Daily: ChessGameStats?
    let tactics: ChessRatingStats?
    let lessons: ChessRatingStats?
    let puzzleRush: PuzzleRush?
    let tournamentsPlayed: Int?
    let matchesWon: Int?

    var winRate: Double {
        let blitzWins = chessBlitz?.record?.win ?? 0
        let bulletWins = chessBullet?.record?.win ?? 0
        let rapidWins = chessRapid?.record?.win ?? 0
        let dailyWins = chessDaily?.record?.win ?? 0
        let chess960Wins = chess960Daily?.record?.win ?? 0

        let totalWins = blitzWins + bulletWins + rapidWins + dailyWins + chess960Wins

        let blitzLosses = chessBlitz?.record?.loss ?? 0
        let bulletLosses = chessBullet?.record?.loss ?? 0
        let rapidLosses = chessRapid?.record?.loss ?? 0
        let dailyLosses = chessDaily?.record?.loss ?? 0
        let chess960Losses = chess960Daily?.record?.loss ?? 0

        let totalLosses = blitzLosses + bulletLosses + rapidLosses + dailyLosses + chess960Losses
        let totalGames = totalWins + totalLosses

        return totalGames > 0 ? (Double(totalWins) / Double(totalGames) * 100.0) : 0.0
    }
}

struct ChessGameStats: Codable {
    let last: ChessRating?
    let record: ChessRecord?
}

struct ChessRating: Codable { let rating: Int? }
struct ChessRatingStats: Codable { let highest: ChessRating? }

struct ChessRecord: Codable {
    let win: Int?
    let loss: Int?
}

struct PuzzleRush: Codable { let best: PuzzleRushScore? }
struct PuzzleRushScore: Codable { let score: Int? }

struct ArchivesResponse: Codable {
    let archives: [String]
}

struct GamesResponse: Codable {
    let games: [ChessGame]
}

struct ChessGame: Codable {
    let url: String?
    let pgn: String?
    let timeControl: String?
    let endTime: Int?   // end_time in API
}

struct TournamentResponse: Codable {
    let name: String?
    let url: String?
    let description: String?
    let startTime: Int?
    let endTime: Int?
    let players: [TournamentPlayer]?
}

struct TournamentPlayer: Codable {
    let username: String?
    let points: Double?
}

struct LeaderboardsResponse: Codable {
    let liveBlitz: [PlayerLeaderboard]?
    let liveBullet: [PlayerLeaderboard]?
    let daily: [PlayerLeaderboard]?
    let arena: [PlayerLeaderboard]?
}

struct PlayerLeaderboard: Codable {
    let username: String?
    let url: String?
    let score: Int?
}

struct ClubResponse: Codable {
    let clubId: String?
    let name: String?
    let description: String?
    let url: String?
    let members: Int?
}

struct PuzzleResponse: Codable {
    let id: String?
    let fen: String?
    let moves: [String]?
    let rating: Int?
    let url: String?
}

// MARK: - SwiftUI Preview
#Preview {
    ChessStatsView()
        .environmentObject(AuthenticationManager())
}
