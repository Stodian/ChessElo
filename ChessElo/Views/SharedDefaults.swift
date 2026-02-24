//
//  SharedDefaults.swift
//  ChessElo
//
//  App Group UserDefaults helpers (APP TARGET ONLY)
//  - Safe access to suiteName only when the App Group container exists
//  - Convenience getters + JSON encode/decode helpers for widgets
//

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

    // MARK: - Basic setters

    static func set(_ value: Any?, forKey key: String) {
        guard let ud = suite() else { return }
        ud.set(value, forKey: key)
    }

    static func remove(_ key: String) {
        guard let ud = suite() else { return }
        ud.removeObject(forKey: key)
    }

    /// Optional: force flush to disk (usually not needed)
    static func synchronize() {
        guard let ud = suite() else { return }
        ud.synchronize()
    }

    // MARK: - Basic getters

    static func bool(_ key: String, default defaultValue: Bool = false) -> Bool {
        guard let ud = suite() else { return defaultValue }
        return ud.object(forKey: key) == nil ? defaultValue : ud.bool(forKey: key)
    }

    /// Optional Int (distinguish missing vs 0)
    static func int(_ key: String) -> Int? {
        guard let ud = suite() else { return nil }
        guard ud.object(forKey: key) != nil else { return nil }
        return ud.integer(forKey: key)
    }

    static func int(_ key: String, default defaultValue: Int) -> Int {
        guard let ud = suite() else { return defaultValue }
        guard ud.object(forKey: key) != nil else { return defaultValue }
        return ud.integer(forKey: key)
    }

    static func double(_ key: String, default defaultValue: Double = 0) -> Double {
        guard let ud = suite() else { return defaultValue }
        guard ud.object(forKey: key) != nil else { return defaultValue }
        return ud.double(forKey: key)
    }

    static func string(_ key: String) -> String? {
        guard let ud = suite() else { return nil }
        return ud.string(forKey: key)
    }

    static func data(_ key: String) -> Data? {
        guard let ud = suite() else { return nil }
        return ud.data(forKey: key)
    }

    // MARK: - JSON helpers (store as String)

    static func setJSON<T: Encodable>(
        _ value: T,
        forKey key: String,
        dateISO8601: Bool = false
    ) {
        guard available else { return }
        let encoder = JSONEncoder()
        if dateISO8601 { encoder.dateEncodingStrategy = .iso8601 }

        guard let data = try? encoder.encode(value),
              let json = String(data: data, encoding: .utf8) else { return }

        set(json, forKey: key)
    }

    static func getJSON<T: Decodable>(
        _ type: T.Type,
        forKey key: String,
        dateISO8601: Bool = false
    ) -> T? {
        guard available else { return nil }
        guard let json = string(key),
              !json.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let data = json.data(using: .utf8) else { return nil }

        let decoder = JSONDecoder()
        if dateISO8601 { decoder.dateDecodingStrategy = .iso8601 }

        return try? decoder.decode(T.self, from: data)
    }
}