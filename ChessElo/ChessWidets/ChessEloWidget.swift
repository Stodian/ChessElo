import WidgetKit
import SwiftUI

struct ChessEloEntry: TimelineEntry {
    let date: Date
    let blitzElo: Int
    let rapidElo: Int
    let bulletElo: Int
}

struct ChessEloProvider: TimelineProvider {
    func placeholder(in context: Context) -> ChessEloEntry {
        ChessEloEntry(date: Date(), blitzElo: 1200, rapidElo: 1300, bulletElo: 1400)
    }

    func getSnapshot(in context: Context, completion: @escaping (ChessEloEntry) -> Void) {
        let entry = ChessEloEntry(date: Date(), blitzElo: 1250, rapidElo: 1350, bulletElo: 1450)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChessEloEntry>) -> Void) {
        Task {
            let stats = try? await ChessAPI.fetchStats(for: "3thanreid")
            let entry = ChessEloEntry(
                date: Date(),
                blitzElo: stats?.blitzRating ?? 0,
                rapidElo: stats?.rapidRating ?? 0,
                bulletElo: stats?.bulletRating ?? 0
            )
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

struct ChessEloWidgetView: View {
    var entry: ChessEloProvider.Entry

    var body: some View {
        VStack(spacing: 5) {
            Text("Chess Elo").font(.headline).bold()
            HStack {
                VStack {
                    Text("Blitz").font(.caption)
                    Text("\(entry.blitzElo)").font(.title2).bold()
                }
                VStack {
                    Text("Rapid").font(.caption)
                    Text("\(entry.rapidElo)").font(.title2).bold()
                }
                VStack {
                    Text("Bullet").font(.caption)
                    Text("\(entry.bulletElo)").font(.title2).bold()
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}



struct ChessEloWidget: Widget {
    let kind: String = "ChessEloWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ChessEloProvider()) { entry in
            ChessEloWidgetView(entry: entry)
        }
        .configurationDisplayName("Chess Elo Ratings")
        .description("Displays your Blitz, Rapid, and Bullet Elo.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}
