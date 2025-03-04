import SwiftUI
import WidgetKit
import Charts
import UIKit



// MARK: - ChessStatsView
struct ChessStatsView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var stats: ChessAPI.ChessStats?
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showMoreStats = false // Toggle for extra stats
    
    var body: some View {
        NavigationStack {
            ZStack {
                ChessboardBackground()
                    .ignoresSafeArea()
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
            
                
                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            ShareLink(
                                item: URL(string: "https://apps.apple.com/app/idYOUR_APP_ID")!,
                                subject: Text("Track Your Chess Stats Instantly!"),
                                message: Text("Want to see your chess stats at a glance? Get a quick reference on your lock screen with this app! Check it out here:")
                            ) {
                                Image(systemName: "square.and.arrow.up")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24) // Adjust size as needed
                                    .foregroundColor(.white)
                                    .padding(.leading, 20)
                            }
                            Spacer()
                            
                            // App Title in Center
                            Text("ChessElo")
                                .font(.title2) // Adjust size as needed
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.top, 15)

                            Spacer()
                            
                            
                            NavigationLink(destination: SettingsView()) {
                                Image(systemName: "gearshape")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24) // Adjust size as needed
                                    .foregroundColor(.white)
                                    .padding(.trailing, 20)
                            }
                        }
                        .padding(.top, -30) // Adjust as needed
                        .frame(maxWidth: .infinity)
                            
                            Spacer()
                        if let stats = stats {
                            VStack(spacing: 20) {
                                // Profile Section
                                if let avatar = stats.avatar, let url = URL(string: avatar) {
                                    AsyncImage(url: url) { image in
                                        image.resizable()
                                            .scaledToFit()
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                            .shadow(radius: 10)
                                    } placeholder: {
                                        ProgressView()
                                    }
                                }
                                
                                Text(stats.username)
                                    .font(.title)
                                    .bold()
                                    .foregroundColor(.white)
                                
                                Text("\u{1F4CD} Country: \(stats.countryCode)")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Divider()
                                    .background(Color.white)
                                    .padding(.horizontal)
                                
                                // Ratings Section
                                VStack(spacing: 12) {
                                    ChessStatRow(title: "♟️ Blitz Rating", value: "\(stats.blitzRating)")
                                    ChessStatRow(title: "⚡ Bullet Rating", value: "\(stats.bulletRating)")
                                    ChessStatRow(title: "⏳ Rapid Rating", value: "\(stats.rapidRating)")
                                }
                            }
                            .padding(.bottom, 0)
                            .padding(.horizontal, 15)
                            
                            // Chevron Dropdown Button
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showMoreStats.toggle()
                                }
                            }) {
                                Image(systemName: "chevron.down")
                                    .rotationEffect(.degrees(showMoreStats ? 180 : 0))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.bottom, 15)
                            }
                            
                            // Extra Stats Section
                            if showMoreStats {
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
                            
                            // Lockscreen Widgets Section
                            VStack(spacing: 16) {
                                HStack(spacing: 10) {
                                    WidgetCardView(title: "Chess Quote", content: {
                                        ChessQuoteWidgetView()
                                    })
                                }
                                .padding(.top, 40)
                                .padding(.horizontal, 10)
                                .padding(.bottom, 40)
                            }
                        } else if !isLoading {
                            Text("No stats available")
                                .foregroundColor(.white.opacity(0.8))
                                .padding()
                        }
                    }
                    .padding(.top, 15)
                    .padding()
            
                }
            }
            .navigationBarHidden(true)
        }
        
        
        
        .onAppear {
            Task {
                do {
                    let session = try await SupabaseManager.shared.supabase.auth.session
                    print("✅ Active session found: \(session)")

                    if let username = try await fetchChessUsernameFromSupabase() {
                        supabaseManager.chessUsername = username
                        fetchChessStats()
                    } else {
                        print("❌ Failed to retrieve Chess.com username.")
                    }
                } catch {
                    print("❌ No active session: \(error)")
                }
            }
        }
    }
    
    
    
    private func fetchChessUsernameFromSupabase() async throws -> String? {
        do {
            // ✅ Ensure there's an active session
            let session = try await SupabaseManager.shared.supabase.auth.session
            let user = session.user
            print("🔍 Fetching Chess.com username for user ID: \(user.id)")

            // ✅ Fetch Chess.com username from Supabase
            let response = try await SupabaseManager.shared.supabase
                .from("users")
                .select("chess_username")
                .eq("id", value: user.id.uuidString)
                .limit(1) // ✅ Fetch at most one row
                .execute()

            // ✅ Directly decode response as an array (no optional binding needed)
            let decodedArray = try JSONSerialization.jsonObject(with: response.data, options: []) as? [[String: Any]]

            // ✅ Extract first row safely
            if let firstRow = decodedArray?.first, let chessUsername = firstRow["chess_username"] as? String {
                print("✅ Chess.com username retrieved: \(chessUsername)")
                return chessUsername
            }

            print("❌ No chess_username found in Supabase")
            return nil
            
        } catch {
            print("❌ Error fetching Chess.com username from Supabase: \(error)")
            return nil
        }
    }
    
    
    
    
    
    
    // MARK: - VisualEffectBlur View
    struct VisualEffectBlur: UIViewRepresentable {
        var blurStyle: UIBlurEffect.Style
        
        func makeUIView(context: Context) -> UIVisualEffectView {
            let view = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
            return view
        }
        
        func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
    }
    
    
    
    
    // MARK: - WidgetCardView for uniform styling
    struct WidgetCardView<Content: View>: View {
        let title: String
        let content: () -> Content
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                content()
                    .padding()
                    .background(VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)) // Glass effect
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1))) // Subtle border
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                    .frame(height: 110)
            }
        }
    }
    
    
    
    // MARK: - Example Usage
    struct RatingsWidgetView: View {
        let entry: ChessStatsEntry
        
        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text("Ratings")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        RatingRow(icon: "♟", title: "Blitz", rating: entry.blitzRating)
                        RatingRow(icon: "⚡", title: "Bullet", rating: entry.bulletRating)
                        RatingRow(icon: "⏳", title: "Rapid", rating: entry.rapidRating)
                    }
                    Spacer()
                }
            }
            .padding()
            .background(VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)) // Frosted glass effect
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1)))
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
    
    

    
    

    struct ChessQuoteWidgetView: View {
        @State private var currentQuoteIndex = 0
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
                
                Divider()
                    .background(Color.white.opacity(0.3))

                VStack(alignment: .leading, spacing: 10) {
                    Text("“\(quotes[currentQuoteIndex].quote)”")
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .italic()
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true) // Ensures full text is shown

                    Text("- \(quotes[currentQuoteIndex].author)")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                .padding(.top, 4)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Automatically change quote every 15 seconds
                .onAppear {
                    Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentQuoteIndex = (currentQuoteIndex + 1) % quotes.count
                        }
                    }
                }
            }
            .padding()
            .frame(width: 320, height: 180) // 🔥 Increased height to fit all text
            .background(VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)) // Frosted glass effect
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1)))
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
    
    
    
    
    
    // MARK: - Helper Views
    struct RatingRow: View {
        let icon: String
        let title: String
        let rating: Int
        
        var body: some View {
            HStack {
                Text("\(icon) \(title): \(rating)")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
            }
        }
    }
    
    
    
    
    // MARK: - GlobalRankWidgetView
    struct GlobalRankWidgetView: View {
        let entry: ChessStatsEntry
        
        var body: some View {
            VStack {
                Text("Global Rank")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("#\(entry.globalRank)")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    
    
    
    
    
    // MARK: - Data Model
    struct ChessStatsEntry: TimelineEntry {
        let date: Date
        let blitzRating: Int
        let bulletRating: Int
        let rapidRating: Int
        let globalRank: Int
    }
    
    
    
    // MARK: - Provider
    struct Provider: TimelineProvider {
        func placeholder(in context: Context) -> ChessStatsEntry {
            ChessStatsEntry(date: Date(), blitzRating: 1500, bulletRating: 1400, rapidRating: 1600, globalRank: 1200)
        }
        
        func getSnapshot(in context: Context, completion: @escaping (ChessStatsEntry) -> ()) {
            let entry = ChessStatsEntry(date: Date(), blitzRating: 1500, bulletRating: 1400, rapidRating: 1600, globalRank: 1200)
            completion(entry)
        }
        
        func getTimeline(in context: Context, completion: @escaping (Timeline<ChessStatsEntry>) -> ()) {
            let entry = ChessStatsEntry(date: Date(), blitzRating: 1500, bulletRating: 1400, rapidRating: 1600, globalRank: 1200)
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }
    
    // MARK: - Ratings Widget
    struct RatingsWidget: Widget {
        let kind: String = "RatingsWidget"
        
        var body: some WidgetConfiguration {
            StaticConfiguration(kind: kind, provider: Provider()) { entry in
                VStack {
                    Text("Ratings")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Blitz: \(entry.blitzRating)")
                    Text("Bullet: \(entry.bulletRating)")
                    Text("Rapid: \(entry.rapidRating)")
                }
                .padding()
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .configurationDisplayName("Chess Ratings")
            .description("Displays your chess ratings.")
            .supportedFamilies([.systemSmall, .systemMedium]) // Supports lock screen widgets
        }
    }
    
    
    
    
    // MARK: - Fetching Data from Chess.com API
    private func fetchChessStats() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // ✅ Get the Chess.com username from Supabase
                let fetchedUsername = try await fetchChessUsernameFromSupabase()
                
                guard let username = fetchedUsername, !username.isEmpty else {
                    await MainActor.run {
                        self.isLoading = false
                        self.errorMessage = "No Chess.com username found."
                    }
                    return
                }
                
                print("🔍 Fetching stats for Chess.com username: \(username)")

                // ✅ Fetch chess stats from API
                let fetchedStats = try await ChessAPI.fetchStats(for: username)

                await MainActor.run {
                    self.stats = fetchedStats
                    self.isLoading = false

                    if let sharedDefaults = UserDefaults(suiteName: "group.com.yourapp.chessstats") {
                        sharedDefaults.set(fetchedStats.blitzRating, forKey: "blitzRating")
                        sharedDefaults.set(fetchedStats.bulletRating, forKey: "bulletRating")
                        sharedDefaults.set(fetchedStats.rapidRating, forKey: "rapidRating")
                        print("✅ Stats saved to UserDefaults")
                    } else {
                        print("❌ Failed to access UserDefaults for App Group")
                    }

                    // ✅ Force widget update only if data is valid
                    WidgetCenter.shared.reloadAllTimelines()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Error fetching chess stats: \(error.localizedDescription)"
                    self.isLoading = false
                }
                print("❌ Error fetching stats: \(error)")
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




// MARK: - ChessAPI Manager with All Endpoints
struct ChessAPI {
    
    // Combined model for player stats (used in the view)
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
    
    // MARK: - Combined: Stats + Profile (for our view)
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
        let decoder = JSONDecoder()
        return try decoder.decode(ArchivesResponse.self, from: data)
    }
    
    // MARK: - Endpoint 4: Monthly Games
    static func fetchGames(for username: String, year: Int, month: Int) async throws -> GamesResponse {
        let monthString = String(format: "%02d", month)
        let url = URL(string: "https://api.chess.com/pub/player/\(username)/games/\(year)/\(monthString)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        return try decoder.decode(GamesResponse.self, from: data)
    }
    
    // MARK: - Endpoint 5: Tournament Information
    static func fetchTournament(for tournamentId: String) async throws -> TournamentResponse {
        let url = URL(string: "https://api.chess.com/pub/tournament/\(tournamentId)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        return try decoder.decode(TournamentResponse.self, from: data)
    }
    
    // MARK: - Endpoint 6: Leaderboards
    static func fetchLeaderboards() async throws -> LeaderboardsResponse {
        let url = URL(string: "https://api.chess.com/pub/leaderboards")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        return try decoder.decode(LeaderboardsResponse.self, from: data)
    }
    
    // MARK: - Endpoint 7: Club Information
    static func fetchClub(for clubId: String) async throws -> ClubResponse {
        let url = URL(string: "https://api.chess.com/pub/club/\(clubId)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        return try decoder.decode(ClubResponse.self, from: data)
    }
    
    // MARK: - Endpoint 8: Daily Puzzle
    static func fetchDailyPuzzle() async throws -> PuzzleResponse {
        let url = URL(string: "https://api.chess.com/pub/puzzle")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        return try decoder.decode(PuzzleResponse.self, from: data)
    }
}

// MARK: - API Response Models

// Player Profile Response
struct ChessProfileResponse: Codable {
    let username: String?
    let avatar: String?
    let country: String?
    
    var countryCode: String {
        return country?.components(separatedBy: "/").last ?? "Unknown"
    }
}

// Player Stats Response
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

struct ChessRating: Codable {
    let rating: Int?
}

struct ChessRatingStats: Codable {
    let highest: ChessRating?
}

struct ChessRecord: Codable {
    let win: Int?
    let loss: Int?
}

struct PuzzleRush: Codable {
    let best: PuzzleRushScore?
}

struct PuzzleRushScore: Codable {
    let score: Int?
}

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
    let endTime: Int?
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
