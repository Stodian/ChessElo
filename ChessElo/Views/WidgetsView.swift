import SwiftUI
import WidgetKit
import ActivityKit
import Charts

// MARK: - Sample Data Models for Graphs

struct RatingEntry: Identifiable {
    let id = UUID()
    let date: Date
    let rating: Int
}

struct GameResultEntry: Identifiable {
    let id = UUID()
    let date: Date
    let eloChange: Int
}

struct WinRateEntry: Identifiable {
    let id = UUID()
    let date: Date
    let winRate: Double
}

struct PuzzleEntry: Identifiable {
    let id = UUID()
    let date: Date
    let difficulty: Int
}

struct TournamentEntry: Identifiable {
    let id = UUID()
    let date: Date
    let tournamentName: String
}

// MARK: - Widget Type Definition

enum WidgetType: String, CaseIterable {
    case ratings = "Chess Ratings"
    case recentGames = "Recent Games"
    case winRate = "Win Rate"
    case dailyPuzzle = "Daily Puzzle"
    case upcomingTournaments = "Tournaments"
    
    var description: String {
        switch self {
        case .ratings:
            return "Display your Rapid, Blitz, and Bullet ratings"
        case .recentGames:
            return "Show your latest game results"
        case .winRate:
            return "Display your win/loss statistics"
        case .dailyPuzzle:
            return "Get a new chess puzzle every day"
        case .upcomingTournaments:
            return "View upcoming chess tournaments"
        }
    }
    
    var previewView: AnyView {
        switch self {
        case .ratings: return AnyView(RatingsWidgetPreview())
        case .recentGames: return AnyView(RecentGamesWidgetPreview())
        case .winRate: return AnyView(WinRateWidgetPreview())
        case .dailyPuzzle: return AnyView(DailyPuzzlePreview())
        case .upcomingTournaments: return AnyView(TournamentsPreview())
        }
    }
    
    var isPremium: Bool {
        switch self {
        case .ratings, .recentGames: return true
        default: return true
        }
    }
}

// MARK: - Main WidgetsView

struct WidgetsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var selectedWidget: WidgetType?
    @State private var showingPlacementGuide = false
    @State private var showingUpgradePrompt = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Background with blurred chessboard
                ChessboardBackground()
                    .ignoresSafeArea()
                    .blur(radius: 10)
                Color.black.opacity(0.75)
                    .ignoresSafeArea()
                
                // Scrollable content
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        Text("Available Widgets")
                            .font(.system(size: 36, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .padding(.top, 80)
                        
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ],
                            spacing: 20
                        ) {
                            ForEach(WidgetType.allCases, id: \.self) { widgetType in
                                ZStack {
                                    // ✅ The actual widget
                                    WidgetPreviewCard(
                                        title: widgetType.rawValue,
                                        description: widgetType.description,
                                        isPremium: widgetType.isPremium,
                                        preview: { widgetType.previewView }
                                    )
                                    .onTapGesture {
                                        if widgetType.isPremium {
                                            showingUpgradePrompt = true
                                        } else {
                                            selectedWidget = widgetType
                                            showingPlacementGuide = true
                                        }
                                    }
                                    
                                    // 🔥 Glassmorphic Blur Overlay for Premium Widgets
                                    if widgetType.isPremium {
                                        VisualEffectBlur(blurStyle: .systemUltraThinMaterial) {
                                            ZStack {
                                                Color.clear.opacity(0.15) // Subtle extra tint
                                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                                
                                                Text("Coming Soon")
                                                    .font(.title3)
                                                    .bold()
                                                    .foregroundColor(.white)
                                                    .padding(.vertical, 6)
                                                    .padding(.horizontal, 16)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                            .fill(Color.clear.opacity(0.2))
                                                            .blur(radius: 2)
                                                    )
                                            }
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    }
                                }
                                
                                
                                
                                
                                .onTapGesture {
                                    if widgetType.isPremium {
                                        showingUpgradePrompt = true
                                    } else {
                                        selectedWidget = widgetType
                                        showingPlacementGuide = true
                                    }
                                }
                                .sheet(isPresented: $showingUpgradePrompt) {
                                    PremiumUpgradeView(isPresented: $showingUpgradePrompt)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Extra bottom padding
                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal)
                }
                
                // Top-right "Done" button overlay
                HStack {
                    Spacer()
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(16)
                }
            }
            .sheet(isPresented: $showingPlacementGuide) {
                if let selectedWidget = selectedWidget {
                    WidgetPlacementGuideView(widgetType: selectedWidget)
                }
            }
            .navigationBarHidden(true)
        }
    }
}





struct VisualEffectBlur<Content: View>: View {
    var blurStyle: UIBlurEffect.Style
    var content: () -> Content

    var body: some View {
        ZStack {
            BlurView(style: blurStyle)
            content()
        }
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.backgroundColor = UIColor.clear.withAlphaComponent(0.1) // Subtle glass tint
        return blurView
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}






// MARK: - Updated WidgetPreviewCard Component

struct WidgetPreviewCard<Preview: View>: View {
    let title: String
    let description: String
    let isPremium: Bool
    let preview: () -> Preview
    
    var body: some View {
        VStack(spacing: 16) {
            // Title and premium crown overlay
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .overlay(
                Group {
                    if isPremium {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .padding(6)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .offset(x: 8, y: -8)
                    }
                },
                alignment: .topTrailing
            )
            
            preview()
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            if isPremium {
                Label("Premium", systemImage: "crown.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.4), radius: 5, x: 0, y: 4)

    }
}




// MARK: - WidgetPlacementGuideView

struct WidgetPlacementGuideView: View {
    let widgetType: WidgetType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Add Widget to Home Screen")
                .font(.title2)
                .bold()
                .foregroundColor(.white)
            
            widgetType.previewView
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            VStack(alignment: .leading, spacing: 16) {
                InstructionRow(number: 1, text: "Exit the app")
                InstructionRow(number: 2, text: "Long press on your home screen")
                InstructionRow(number: 3, text: "Tap the + button in the top left")
                InstructionRow(number: 4, text: "Search for 'Chess Elo'")
                InstructionRow(number: 5, text: "Select this widget and place it")
            }
            .padding()
            
            Button("Got it") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .padding()
        .background(Color.black)
        .cornerRadius(20)
        .padding()
    }
}



// MARK: - Widget Preview Components with Graphs

struct RatingsWidgetPreview: View {
    // Sample data for ratings graph
    let sampleRatings: [RatingEntry] = [
        RatingEntry(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, rating: 1150),
        RatingEntry(date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, rating: 1160),
        RatingEntry(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, rating: 1175),
        RatingEntry(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, rating: 1180),
        RatingEntry(date: Date(), rating: 1180)
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                RatingItem(title: "Rapid", rating: "1180")
                RatingItem(title: "Blitz", rating: "2100")
                RatingItem(title: "Bullet", rating: "700")
            }
            .padding(.bottom, 8)
            
            // Line chart for ratings over time
            Chart(sampleRatings) { entry in
                LineMark(
                    x: .value("Date", entry.date),
                    y: .value("Rating", entry.rating)
                )
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 3))
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
    }
}

struct RatingItem: View {
    let title: String
    let rating: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
            Text(rating)
                .font(.headline)
        }
        .foregroundColor(.white)
    }
}

struct RecentGamesWidgetPreview: View {
    // Sample data for recent game results over time
    let sampleGames: [GameResultEntry] = [
        GameResultEntry(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, eloChange: +8),
        GameResultEntry(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, eloChange: -12),
        GameResultEntry(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, eloChange: 0)
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(sampleGames) { game in
                GameResultRow(result: game.eloChange >= 0 ? "Win" : (game.eloChange < 0 ? "Loss" : "Draw"), rating: game.eloChange >= 0 ? "+\(game.eloChange)" : "\(game.eloChange)")
            }
            
            // Bar chart for elo change over time
            Chart(sampleGames) { entry in
                BarMark(
                    x: .value("Date", entry.date),
                    y: .value("Elo Change", abs(entry.eloChange))
                )
                .foregroundStyle(entry.eloChange >= 0 ? Color.green : Color.red)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 3))
            }
        }
        .padding()
    }
}

struct GameResultRow: View {
    let result: String
    let rating: String
    
    var body: some View {
        HStack {
            Text(result)
            Spacer()
            Text(rating)
        }
        .foregroundColor(.white)
    }
}

struct WinRateWidgetPreview: View {
    // Sample data for win rate over time
    let sampleWinRate: [WinRateEntry] = [
        WinRateEntry(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, winRate: 60),
        WinRateEntry(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, winRate: 65),
        WinRateEntry(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, winRate: 68)
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Win Rate")
                .font(.headline)
            Text("65%")
                .font(.system(size: 36, weight: .bold))
            Text("Last 30 Days")
                .font(.caption)
            
            // Line chart for win rate changes
            Chart(sampleWinRate) { entry in
                LineMark(
                    x: .value("Date", entry.date),
                    y: .value("Win Rate", entry.winRate)
                )
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 3))
            }
        }
        .foregroundColor(.white)
        .padding()
    }
}

struct DailyPuzzlePreview: View {
    // Sample data for daily puzzle difficulty trend
    let samplePuzzles: [PuzzleEntry] = [
        PuzzleEntry(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, difficulty: 1700),
        PuzzleEntry(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, difficulty: 1750),
        PuzzleEntry(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, difficulty: 1800),
        PuzzleEntry(date: Date(), difficulty: 1800)
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Daily Puzzle")
                .font(.headline)
            Image(systemName: "puzzlepiece.fill")
                .font(.system(size: 36))
            Text("Difficulty: 1800")
                .font(.caption)
            
            // Area chart for puzzle difficulty trend
            Chart(samplePuzzles) { entry in
                AreaMark(
                    x: .value("Date", entry.date),
                    y: .value("Difficulty", entry.difficulty)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.2)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 3))
            }
        }
        .foregroundColor(.white)
        .padding()
    }
}

struct TournamentsPreview: View {
    // Sample data for upcoming tournaments timeline
    let sampleTournaments: [TournamentEntry] = [
        TournamentEntry(date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, tournamentName: "City Open"),
        TournamentEntry(date: Calendar.current.date(byAdding: .day, value: 3, to: Date())!, tournamentName: "Chess Masters"),
        TournamentEntry(date: Calendar.current.date(byAdding: .day, value: 7, to: Date())!, tournamentName: "International Cup")
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Next Tournament")
                .font(.headline)
            if let next = sampleTournaments.first {
                Text(next.tournamentName)
                    .font(.system(size: 24, weight: .bold))
                Text("In \(Calendar.current.dateComponents([.day], from: Date(), to: next.date).day ?? 0) days")
                    .font(.caption)
            }
            
            // Timeline chart for tournaments (using a simple bar chart)
            Chart(sampleTournaments) { entry in
                BarMark(
                    x: .value("Tournament", entry.tournamentName),
                    y: .value("Days", Calendar.current.dateComponents([.day], from: Date(), to: entry.date).day ?? 0)
                )
                .foregroundStyle(Color.purple)
            }
            .chartXAxis {
                AxisMarks(position: .bottom)
            }
        }
        .foregroundColor(.white)
        .padding()
    }
}




// MARK: - InstructionRow Component

struct InstructionRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .frame(width: 24, height: 24)
                .background(Color.white.opacity(0.2))
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}







struct PremiumUpgradeView: View {
    @Binding var isPresented: Bool
    @State private var isLoading = false
    @State private var showConfirmation = false

    var body: some View {
        ZStack {
            ChessboardBackground()
                .ignoresSafeArea()
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer().frame(height: 100)

                // Icon & Title
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundColor(.yellow)
                        .shadow(radius: 10)

                    Text("Premium Features Coming Soon")
                        .font(.custom("Palatino-Bold", size: 28))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }

                // Description
                Text("We’re working on exclusive widgets and detailed analytics for premium users. Be the first to know when it launches by registering your interest!")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                // Register Interest Button
                Button(action: {
                    isLoading = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isLoading = false
                        showConfirmation = true
                    }
                }) {
                    ZStack {
                        Text("Register Your Interest")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.Maroon, .DarkMaroon]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .opacity(isLoading ? 0 : 1)

                        if isLoading {
                            ProgressView().tint(.white)
                        }
                    }
                }
                .disabled(isLoading)
                .padding(.horizontal)

                // Close Button
                Button(action: {
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Text("Not Now")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()
            }
        }
        .alert("Thanks for your interest!", isPresented: $showConfirmation, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text("You'll be notified when premium features become available.")
        })
    }
}




#Preview {
    WidgetsView()
        .environmentObject(AuthenticationManager())
}
