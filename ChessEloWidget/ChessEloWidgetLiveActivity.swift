//
//  ChessEloWidgetExtensionLiveActivity.swift
//  ChessEloWidgetExtension
//
//  Created by Ethan Reid on 23/02/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ChessEloWidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct ChessEloWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ChessEloWidgetExtensionAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension ChessEloWidgetExtensionAttributes {
    fileprivate static var preview: ChessEloWidgetExtensionAttributes {
        ChessEloWidgetExtensionAttributes(name: "World")
    }
}

extension ChessEloWidgetExtensionAttributes.ContentState {
    fileprivate static var smiley: ChessEloWidgetExtensionAttributes.ContentState {
        ChessEloWidgetExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ChessEloWidgetExtensionAttributes.ContentState {
         ChessEloWidgetExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: ChessEloWidgetExtensionAttributes.preview) {
   ChessEloWidgetExtensionLiveActivity()
} contentStates: {
    ChessEloWidgetExtensionAttributes.ContentState.smiley
    ChessEloWidgetExtensionAttributes.ContentState.starEyes
}
