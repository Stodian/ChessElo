import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> RatingsEntry {
        RatingsEntry(date: Date(), rapid: 1200, blitz: 1200, bullet: 1200)
    }

    func getSnapshot(in context: Context, completion: @escaping (RatingsEntry) -> ()) {
        let entry = RatingsEntry(date: Date(), rapid: 1180, blitz: 2100, bullet: 700)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = RatingsEntry(date: Date(), rapid: 1180, blitz: 2100, bullet: 700)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct RatingsEntry: TimelineEntry {
    let date: Date
    let rapid: Int
    let blitz: Int
    let bullet: Int
}

struct ChessEloWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            Color.black
            
            VStack(spacing: 12) {
                Text("Chess Ratings")
                    .font(.headline)
                
                HStack(spacing: 16) {
                    RatingColumn(title: "Rapid", rating: entry.rapid)
                    RatingColumn(title: "Blitz", rating: entry.blitz)
                    RatingColumn(title: "Bullet", rating: entry.bullet)
                }
            }
            .foregroundStyle(.white)
        }
    }
}

struct RatingColumn: View {
    let title: String
    let rating: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
            Text("\(rating)")
                .font(.system(.body, design: .rounded, weight: .bold))
        }
    }
}

@main
struct ChessEloWidget: Widget {
    let kind: String = "ChessEloWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ChessEloWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Chess Ratings")
        .description("Display your chess ratings")
        .supportedFamilies([.systemSmall])
    }
} 