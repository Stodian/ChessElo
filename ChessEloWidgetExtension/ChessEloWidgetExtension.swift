import WidgetKit
import SwiftUI

// Entry model for widget
struct ChessStatsEntry: TimelineEntry {
    let date: Date
    let blitzRating: Int
    let bulletRating: Int
    let rapidRating: Int
    let globalRank: Int
}



struct ContainerBackgroundIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.containerBackground(.fill.tertiary, for: .widget) // ✅ iOS 17+
        } else {
            content // ✅ iOS 16 and earlier
        }
    }
}



// Timeline Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ChessStatsEntry {
        ChessStatsEntry(date: Date(), blitzRating: 1500, bulletRating: 1600, rapidRating: 1700, globalRank: 1200)
    }

    func getSnapshot(in context: Context, completion: @escaping (ChessStatsEntry) -> Void) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.yourapp.chessstats")

        let blitzRating = sharedDefaults?.integer(forKey: "blitzRating") ?? 1500
        let bulletRating = sharedDefaults?.integer(forKey: "bulletRating") ?? 1600
        let rapidRating = sharedDefaults?.integer(forKey: "rapidRating") ?? 1700

        let entry = ChessStatsEntry(date: Date(), blitzRating: blitzRating, bulletRating: bulletRating, rapidRating: rapidRating, globalRank: 1200)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChessStatsEntry>) -> Void) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.yourapp.chessstats")

        let blitzRating = sharedDefaults?.integer(forKey: "blitzRating") ?? 1500
        let bulletRating = sharedDefaults?.integer(forKey: "bulletRating") ?? 1600
        let rapidRating = sharedDefaults?.integer(forKey: "rapidRating") ?? 1700

        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!

        let entry = ChessStatsEntry(
            date: currentDate,
            blitzRating: blitzRating,
            bulletRating: bulletRating,
            rapidRating: rapidRating,
            globalRank: 1200
        )

        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}



// Main Widget View
struct ChessEloWidgetEntryView: View {
    var entry: ChessStatsEntry

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 1) {
                Text("Ratings")
                    .font(.system(size: 7, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0))

                Divider()
                    .background(Color.white.opacity(0))

                VStack(alignment: .leading, spacing: 2) {
                    RatingRow(icon: "♟️", title: "Blitz", rating: entry.blitzRating)
                    RatingRow(icon: "⚡", title: "Bullet", rating: entry.bulletRating)
                    RatingRow(icon: "⏳", title: "Rapid", rating: entry.rapidRating)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 5)
                .lineLimit(1)

                Spacer()
            }
            .padding(.leading, 20)
            .padding(.bottom, 2)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(
                Color.black.opacity(0))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0)))
            .shadow(color: Color.black.opacity(0), radius: 10, x: 0, y: 5)
            .containerBackground(.fill, for: .widget)
        }
    }
}



@main
struct ChessEloWidgetExtension: Widget {
    let kind: String = "ChessEloWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ChessEloWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Chess Elo Widget")
        .description("Displays your latest Chess Elo rating.")
        .supportedFamilies([
            .accessoryRectangular,
        ])
    }
}



// Rating Row Component
struct RatingRow: View {
    let icon: String
    let title: String
    let rating: Int

    var body: some View {
        HStack {
            Text("\(icon) \(title): \(rating)")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
        }
    }
}



// VisualEffectBlur Component for Background
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}



struct ChessEloLockScreenView: View {
    var entry: ChessStatsEntry

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Blitz: \(entry.blitzRating)")
                Text("Bullet: \(entry.bulletRating)")
                Text("Rapid: \(entry.rapidRating)")
            }
            .font(.system(size: 8, weight: .regular, design: .rounded))
            .foregroundColor(.white.opacity(0.85))
            .lineLimit(1)
            .frame(height: 2)
            .scaledToFit()
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}



#Preview(as: .accessoryRectangular) {
    ChessEloWidgetExtension()
} timeline: {
    ChessStatsEntry(date: Date(), blitzRating: 1500, bulletRating: 1600, rapidRating: 1700, globalRank: 1200)
}


