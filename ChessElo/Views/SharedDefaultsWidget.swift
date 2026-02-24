//
//  SharedDefaultsWidget.swift
//  ChessEloWidget
//
//  App Group UserDefaults helpers (WIDGET TARGET ONLY)
//

import Foundation
import SwiftUI
import WidgetKit

enum SharedDefaultsWidget {
    static let groupID = "group.com.stodian.chesselo"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)
    }

    private static var shared: UserDefaults? {
        guard containerURL != nil else { return nil }
        return UserDefaults(suiteName: groupID)
    }

    static func bool(_ key: String) -> Bool {
        shared?.bool(forKey: key) ?? false
    }

    static func int(_ key: String) -> Int {
        shared?.integer(forKey: key) ?? 0
    }

    static func double(_ key: String) -> Double {
        shared?.double(forKey: key) ?? 0
    }

    static func string(_ key: String) -> String? {
        shared?.string(forKey: key)
    }

    static func data(_ key: String) -> Data? {
        shared?.data(forKey: key)
    }
}

// MARK: - Widget background helper

private struct WidgetBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.containerBackground(.fill.tertiary, for: .widget)
        } else {
            content
                .padding()
                .background(Color.black.opacity(0.25))
        }
    }
}

extension View {
    func widgetBackground() -> some View {
        modifier(WidgetBackground())
    }
}