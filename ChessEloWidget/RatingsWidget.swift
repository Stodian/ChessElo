import WidgetKit
import SwiftUI
import Foundation

// MARK: - Entry

struct ChessStatsEntry: TimelineEntry {
    let date: Date
    let blitzRating: Int
    let bulletRating: Int
    let rapidRating: Int
    let globalRank: Int
}

// MARK: - iOS 17 containerBackground fallback

struct ContainerBackgroundIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.containerBackground(.fill.tertiary, for: .widget)
        } else {
            content
        }
    }
}

// MARK: - SharedDefaults (App Group-safe)

enum SharedDefaults {
    static let groupID = "group.com.stodian.chesselo"

    /// If this is nil, this process does NOT have a usable App Group container.
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)
    }

    /// Only create suite-backed defaults when the container exists.
    static var shared: UserDefaults? {
        guard containerURL != nil else { return nil }
        return UserDefaults(suiteName: groupID)
    }
}

// MARK: - Provider

struct Provider: TimelineProvider {

    func placeholder(in context: Context) -> ChessStatsEntry {
        ChessStatsEntry(
            date: Date(),
            blitzRating: 1500,
            bulletRating: 1600,
            rapidRating: 1700,
            globalRank: 1200
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ChessStatsEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChessStatsEntry>) -> Void) {
        let entry = makeEntry()
        let now = Date()
        let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }

    private func makeEntry() -> ChessStatsEntry {
        // ✅ Only touch app-group defaults if the container exists.
        if let sharedDefaults = SharedDefaults.shared {
            let blitz = sharedDefaults.integer(forKey: "blitzRating")
            let bullet = sharedDefaults.integer(forKey: "bulletRating")
            let rapid = sharedDefaults.integer(forKey: "rapidRating")

            return ChessStatsEntry(
                date: Date(),
                blitzRating: blitz,
                bulletRating: bullet,
                rapidRating: rapid,
                globalRank: 1200
            )
        } else {
            // In previews / misconfigured entitlement contexts, do NOT access suite defaults.
            return ChessStatsEntry(
                date: Date(),
                blitzRating: 0,
                bulletRating: 0,
                rapidRating: 0,
                globalRank: 1200
            )
        }
    }
}

// MARK: - Entry View

struct ChessEloWidgetEntryView: View {
    var entry: ChessStatsEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            ChessEloLockScreenView(entry: entry)
        case .systemSmall:
            ChessEloSystemSmallView(entry: entry)
        case .systemMedium:
            ChessEloSystemMediumView(entry: entry)
        default:
            EmptyView()
        }
    }
}

// MARK: - Widget

@main
struct ChessEloWidgetExtension: Widget {
    private let kind: String = "ChessEloWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ChessEloWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Chess Elo Widget")
        .description("Displays your latest Chess Elo ratings.")
        .supportedFamilies([.accessoryRectangular, .systemSmall, .systemMedium])
    }
}

// MARK: - Views

struct ChessEloLockScreenView: View {
    var entry: ChessStatsEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("♟️ Blitz \(entry.blitzRating)")
            Text("⚡ Bullet \(entry.bulletRating)")
            Text("⏳ Rapid \(entry.rapidRating)")
        }
        .font(.caption2)
        .lineLimit(1)
        .modifier(ContainerBackgroundIfAvailable())
    }
}

struct ChessEloSystemSmallView: View {
    var entry: ChessStatsEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Chess Elo")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    smallRow("Blitz", entry.blitzRating)
                    smallRow("Bullet", entry.bulletRating)
                    smallRow("Rapid", entry.rapidRating)
                }
                Spacer()
            }
        }
        .padding(12)
        .modifier(ContainerBackgroundIfAvailable())
    }

    private func smallRow(_ label: String, _ value: Int) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text("\(value)").fontWeight(.semibold).monospacedDigit()
        }
        .font(.caption2)
    }
}

struct ChessEloSystemMediumView: View {
    var entry: ChessStatsEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Chess Elo")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                mediumRow("Blitz", entry.blitzRating)
                mediumRow("Bullet", entry.bulletRating)
                mediumRow("Rapid", entry.rapidRating)
            }
            Spacer()
        }
        .padding(14)
        .modifier(ContainerBackgroundIfAvailable())
    }

    private func mediumRow(_ label: String, _ value: Int) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text("\(value)").fontWeight(.semibold).monospacedDigit()
        }
        .font(.caption)
    }
}

// MARK: - Preview

struct ChessEloWidget_Previews: PreviewProvider {
    static var previews: some View {
        ChessEloWidgetEntryView(entry: ChessStatsEntry(
            date: Date(),
            blitzRating: 1500,
            bulletRating: 1600,
            rapidRating: 1700,
            globalRank: 1200
        ))
        .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
    }
}
