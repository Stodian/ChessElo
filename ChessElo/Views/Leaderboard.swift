//
//  Leaderboard.swift
//  ChessElo
//
//  Premium Team Leaderboard
//  - Top-right menu sheet for Join / Create / Share code / Leave team
//  - Updates users.team_id
//  - Leaderboard pulls teammates from users + stats from user_chess_stats
//

import SwiftUI
import Supabase
import UIKit

struct Leaderboard: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager

    // MARK: - UI State
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showCopiedToast = false
    @State private var showTeamSheet = false
    @State private var refreshInFlight = false

    // Sheet loading states
    @State private var isJoining = false
    @State private var isCreatingTeam = false
    @State private var isLeavingTeam = false
    @State private var showLeaveConfirm = false

    // MARK: - Team State
    @State private var myTeamId: String?
    @State private var myTeamName: String?
    @State private var myTeamJoinCode: String?

    // Inputs
    @State private var joinCode: String = ""
    @State private var newTeamName: String = ""

    // Leaderboard
    @State private var rows: [LeaderboardRow] = []

    // MARK: - Sorting
    private enum LeaderboardSort: String, CaseIterable, Identifiable {
        case total = "Total"
        case blitz = "Blitz"
        case bullet = "Bullet"
        case rapid = "Rapid"
        case lastGame = "Last game"

        var id: String { rawValue }
    }

    @State private var sortBy: LeaderboardSort = .total

    // MARK: - Models
    struct MyUserRow: Decodable { let team_id: String? }

    struct TeamRow: Decodable {
        let id: String
        let name: String?
        let join_code: String?
        let slug: String?
        let created_by: String?
    }

    struct UserRow: Decodable, Identifiable {
        let id: String
        let display_name: String?
        let chess_username: String?
        let team_id: String?
    }

    struct UserStatsRow: Decodable {
        let user_id: String
        let chess_avatar_url: String?
        let blitz_rating: Int?
        let rapid_rating: Int?
        let bullet_rating: Int?
        let daily_rating: Int?
        let last_game_played_at: String?
        let stats_last_synced_at: String?
    }

    struct LeaderboardRow: Identifiable {
        let id: String
        let displayName: String
        let username: String?
        let avatarURL: String?
        let blitz: Int
        let rapid: Int
        let bullet: Int
        let daily: Int

        // Optional last game date (if available)
        let lastGamePlayedAt: Date?
    }

    private struct RefreshTeamStatsResponse: Decodable {
        let ok: Bool
        let skipped: Bool?
        let reason: String?
        let updated: Int?
        let failed: Int?
        let stats_last_refreshed_at: String?
    }
    
    
    var body: some View {
        ZStack {
            ChessboardBackground().ignoresSafeArea()
            Color.black.opacity(0.70).ignoresSafeArea()

            VStack(spacing: 14) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        leaderboardMainCard
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
                .refreshable { await load() }
            }

            if isLoading {
                loadingOverlay
            }

            // Optional little toast if you use showCopiedToast somewhere
            if showCopiedToast {
                VStack {
                    Spacer()
                    Text("Copied!")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(Color.black.opacity(0.7), in: Capsule())
                        .padding(.bottom, 30)
                }
                .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
        .onAppear { Task { await load() } }
        .sheet(isPresented: $showTeamSheet) {
            teamSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            "Leave team?",
            isPresented: $showLeaveConfirm,
            titleVisibility: .visible
        ) {
            Button("Leave team", role: .destructive) {
                Task { await leaveTeam() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will be removed from this team. You can rejoin later with the code.")
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }
}

// MARK: - UI
private extension Leaderboard {

    var hasTeam: Bool {
        !(myTeamId?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.10), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Leaderboard")
                .font(.title2.bold())
                .foregroundColor(.white)

            Spacer()

            Button { showTeamSheet = true } label: {
                Image(systemName: "ellipsis")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.10), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }

    var leaderboardMainCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("Scoreboard")
                    .font(.title3.bold())
                    .foregroundColor(.white)

                Spacer()

                // ✅ Dropdown to choose ranking
                Menu {
                    Picker("Rank by", selection: $sortBy) {
                        ForEach(LeaderboardSort.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(sortBy.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white.opacity(0.75))

                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white.opacity(0.65))
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.white.opacity(0.10), in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
            }

            Divider().background(Color.white.opacity(0.18))

            if !hasTeam {
                VStack(spacing: 6) {
                    Text("Join or create a team to see the scoreboard.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.70))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)

            } else if rows.isEmpty && !isLoading {
                VStack(spacing: 6) {
                    Text("No players yet.")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.90))

                    Text("Your team exists, but no members were found.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)

            } else {
                VStack(spacing: 10) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { idx, row in
                        leaderboardRow(rank: idx + 1, row: row)
                    }
                }
            }
        }
        .padding(16)
        .background(BlurView(style: .systemUltraThinMaterialDark))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .onChange(of: sortBy) { _ in
            rows.sort { valueForRow($0) > valueForRow($1) }
        }
    }

    func totalScore(_ row: LeaderboardRow) -> Int {
        row.blitz + row.bullet + row.rapid
    }

    func valueForRow(_ row: LeaderboardRow) -> Int {
        switch sortBy {
        case .total:
            return totalScore(row)
        case .blitz:
            return row.blitz
        case .bullet:
            return row.bullet
        case .rapid:
            return row.rapid
        case .lastGame:
            // Most recent should be highest → convert Date to seconds
            return Int(row.lastGamePlayedAt?.timeIntervalSince1970 ?? 0)
        }
    }

    func leaderboardRow(rank: Int, row: LeaderboardRow) -> some View {
        let value = valueForRow(row)

        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 34, height: 34)
                Text("\(rank)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))

            avatarView(urlString: row.avatarURL)

            VStack(alignment: .leading, spacing: 2) {
                Text(row.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                if let u = row.username, !u.isEmpty {
                    Text("@\(u)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(1)
                }
            }

            Spacer()

            // If "Last game" is selected, show a friendlier label (optional)
            if sortBy == .lastGame {
                Text(row.lastGamePlayedAt.map { shortRelativeDate($0) } ?? "—")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
            } else {
                Text("\(value)")
                    .font(.headline.monospacedDigit())
                    .foregroundColor(.white)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func shortRelativeDate(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "\(seconds)s" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h" }
        let days = hours / 24
        return "\(days)d"
    }

    private func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let urlError = error as? URLError, urlError.code == .cancelled { return true }
        return false
    }

    func avatarView(urlString: String?) -> some View {
        Group {
            if let s = urlString, let url = URL(string: s), !s.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().tint(.white.opacity(0.85))
                            .frame(width: 40, height: 40)
                    case .success(let image):
                        image.resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    default:
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 40, height: 40)
                            .overlay(Image(systemName: "person.fill").foregroundColor(.white.opacity(0.7)))
                    }
                }
            } else {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 40, height: 40)
                    .overlay(Image(systemName: "person.fill").foregroundColor(.white.opacity(0.7)))
            }
        }
        .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
    }

    var loadingOverlay: some View {
        VStack(spacing: 12) {
            ProgressView().tint(.white)
            Text("Loading...")
                .foregroundColor(.white.opacity(0.85))
                .font(.headline)
        }
        .padding(18)
        .background(BlurView(style: .systemUltraThinMaterialDark))
        .cornerRadius(14)
    }
}

// MARK: - Team Sheet
private extension Leaderboard {

    var teamSheet: some View {
        ZStack {
            ChessboardBackground().ignoresSafeArea()
            Color.black.opacity(0.82).ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        currentTeamCard
                        joinCard
                        createCard

                        Spacer(minLength: 18)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    var sheetHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.3.fill")
                .foregroundColor(.white.opacity(0.9))

            Text("Team")
                .font(.title2.bold())
                .foregroundColor(.white)

            Spacer()

            Button { showTeamSheet = false } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.10), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    var currentTeamCard: some View {
        let code = (myTeamJoinCode ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let teamName = (myTeamName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Current team")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.70))

                Spacer()

                if hasTeam, !code.isEmpty {
                    Text(code)
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundColor(.white.opacity(0.95))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color.white.opacity(0.10), in: Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
            }

            Text(hasTeam ? (teamName.isEmpty ? "Your Team" : teamName) : "Not in a team")
                .font(.headline)
                .foregroundColor(.white)

            Text(hasTeam
                 ? "Share the code so friends can join and appear on the leaderboard."
                 : "Join a team with a code, or create your own.")
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.65))

            if hasTeam {
                HStack(spacing: 10) {
                    Button { copyToClipboard(code) } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.on.doc")
                            Text("Copy code").font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(code.isEmpty)

                    ShareLink(item: "Join my ChessElo team!\n\nTeam code: \(code)\n\nOpen ChessElo → Leaderboard → paste code to join.") {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share").font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(code.isEmpty)
                }

                Button {
                    showLeaveConfirm = true
                } label: {
                    HStack {
                        if isLeavingTeam { ProgressView().tint(.white) }
                        Text(isLeavingTeam ? "Leaving..." : "Leave team")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isLeavingTeam)
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(BlurView(style: .systemUltraThinMaterialDark))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    var joinCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Join with code")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                if isJoining { ProgressView().tint(.white) }
            }

            Text("Enter a team code to join your friends.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.65))

            TextField("Team code", text: $joinCode)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding()
                .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
                .foregroundColor(.white)
                .font(.system(.body, design: .monospaced))

            Button {
                Task {
                    await joinTeam()
                    if hasTeam { showTeamSheet = false }
                }
            } label: {
                HStack {
                    Text(isJoining ? "Joining..." : (hasTeam ? "Change team" : "Join team"))
                        .font(.headline)
                    Spacer()
                    Image(systemName: "arrow.right").font(.subheadline.weight(.semibold))
                }
                .foregroundColor(.white)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.Maroon, .DarkMaroon]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
            }
            .buttonStyle(.plain)
            .disabled(isJoining || joinCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(14)
        .background(BlurView(style: .systemUltraThinMaterialDark))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    var createCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Create a team")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                if isCreatingTeam { ProgressView().tint(.white) }
            }

            Text("Create a new team and get a shareable join code.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.65))

            TextField("Team name", text: $newTeamName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled(true)
                .padding()
                .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
                .foregroundColor(.white)

            Button {
                Task {
                    await createTeam()
                    if hasTeam { showTeamSheet = false }
                }
            } label: {
                HStack {
                    Text(isCreatingTeam ? "Creating..." : "Create team")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "plus").font(.subheadline.weight(.semibold))
                }
                .foregroundColor(.white)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.Maroon, .DarkMaroon]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
            }
            .buttonStyle(.plain)
            .disabled(isCreatingTeam || newTeamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Text("You’ll automatically join the team after creating it.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.60))
        }
        .padding(14)
        .background(BlurView(style: .systemUltraThinMaterialDark))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    func copyToClipboard(_ text: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        UIPasteboard.general.string = t
        withAnimation(.easeInOut(duration: 0.2)) { showCopiedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 0.2)) { showCopiedToast = false }
        }
    }
}

// MARK: - Data
private extension Leaderboard {

    
    private func shouldRefreshTeam(
        expectedUserIds: [String],
        statsRows: [UserStatsRow]
    ) -> Bool {
        let iso = ISO8601DateFormatter()

        // If we don't have stats for everyone yet, refresh to populate missing rows
        if statsRows.count < expectedUserIds.count {
            return true
        }

        // If anyone has never synced, refresh
        if statsRows.contains(where: { ($0.stats_last_synced_at ?? "").isEmpty }) {
            return true
        }

        // Use the OLDEST sync time, not newest
        let oldest = statsRows
            .compactMap { $0.stats_last_synced_at }
            .compactMap { iso.date(from: $0) }
            .min()

        guard let oldest else { return true }
        return Date().timeIntervalSince(oldest) > (15 * 60)
    }
    
    
    func load() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        defer { Task { @MainActor in isLoading = false } }

        do {
            let session = try await SupabaseManager.shared.supabase.auth.session
            let userId = session.user.id.uuidString

            let me: MyUserRow = try await SupabaseManager.shared.supabase
                .from("users")
                .select("team_id")
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            await MainActor.run { myTeamId = me.team_id }

            if let tid = me.team_id, !tid.isEmpty {
                if let team: TeamRow = try? await SupabaseManager.shared.supabase
                    .from("teams")
                    .select("id, name, join_code, slug, created_by")
                    .eq("id", value: tid)
                    .single()
                    .execute()
                    .value {

                    await MainActor.run {
                        myTeamName = team.name
                        myTeamJoinCode = team.join_code
                        if let code = team.join_code, !code.isEmpty { joinCode = code }
                    }
                } else {
                    await MainActor.run {
                        myTeamName = nil
                        myTeamJoinCode = nil
                    }
                }

                await loadLeaderboard(teamId: tid)
            } else {
                await MainActor.run {
                    rows = []
                    myTeamName = nil
                    myTeamJoinCode = nil
                }
            }

        } catch {
            if isCancellation(error) { return }
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    func loadLeaderboard(teamId: String) async {
        do {
            // 1) Load teammates
            let teammates: [UserRow] = try await SupabaseManager.shared.supabase
                .from("users")
                .select("id, display_name, chess_username, team_id")
                .eq("team_id", value: teamId)
                .execute()
                .value

            let ids = teammates.map(\.id)

            // 2) Load cached stats FIRST (fast UI)
            var statsByUserId: [String: UserStatsRow] = [:]

            if !ids.isEmpty {
                let statsRows: [UserStatsRow] = try await SupabaseManager.shared.supabase
                    .from("user_chess_stats")
                    .select("user_id, chess_avatar_url, blitz_rating, rapid_rating, bullet_rating, daily_rating, last_game_played_at, stats_last_synced_at")
                    .in("user_id", values: ids)
                    .execute()
                    .value

                statsByUserId = Dictionary(uniqueKeysWithValues: statsRows.map { ($0.user_id, $0) })
            }

            // 3) Build rows from cached stats and show immediately
            let iso = ISO8601DateFormatter()

            let mergedCached: [LeaderboardRow] = teammates.map { u in
                let display = (u.display_name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
                    ? (u.display_name ?? "")
                    : (u.chess_username ?? "Player")

                let stats = statsByUserId[u.id]
                let lastDate: Date? = {
                    guard let s = stats?.last_game_played_at, !s.isEmpty else { return nil }
                    return iso.date(from: s)
                }()

                return LeaderboardRow(
                    id: u.id,
                    displayName: display,
                    username: u.chess_username,
                    avatarURL: stats?.chess_avatar_url,
                    blitz: stats?.blitz_rating ?? 0,
                    rapid: stats?.rapid_rating ?? 0,
                    bullet: stats?.bullet_rating ?? 0,
                    daily: stats?.daily_rating ?? 0,
                    lastGamePlayedAt: lastDate
                )
            }

            await MainActor.run {
                rows = Array(mergedCached.sorted { valueForRow($0) > valueForRow($1) }.prefix(50))
            }

            // 4) ALWAYS attempt a refresh in the background (server cooldown will skip if too soon)
            guard !refreshInFlight else { return }
            await MainActor.run { refreshInFlight = true }

            Task {
                defer { Task { @MainActor in refreshInFlight = false } }

                do {
                    let session = try await SupabaseManager.shared.supabase.auth.session

                    try await SupabaseManager.shared.supabase.functions.invoke(
                        "refresh-team-stats",
                        options: .init(
                            headers: ["Authorization": "Bearer \(session.accessToken)"],
                            body: ["team_id": teamId]
                        )
                    )

                    // 5) Re-fetch stats AFTER refresh attempt and update UI again
                    guard !ids.isEmpty else { return }

                    let refreshedRows: [UserStatsRow] = try await SupabaseManager.shared.supabase
                        .from("user_chess_stats")
                        .select("user_id, chess_avatar_url, blitz_rating, rapid_rating, bullet_rating, daily_rating, last_game_played_at, stats_last_synced_at")
                        .in("user_id", values: ids)
                        .execute()
                        .value

                    let refreshedById = Dictionary(uniqueKeysWithValues: refreshedRows.map { ($0.user_id, $0) })

                    let mergedRefreshed: [LeaderboardRow] = teammates.map { u in
                        let display = (u.display_name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
                            ? (u.display_name ?? "")
                            : (u.chess_username ?? "Player")

                        let stats = refreshedById[u.id]
                        let lastDate: Date? = {
                            guard let s = stats?.last_game_played_at, !s.isEmpty else { return nil }
                            return iso.date(from: s)
                        }()

                        return LeaderboardRow(
                            id: u.id,
                            displayName: display,
                            username: u.chess_username,
                            avatarURL: stats?.chess_avatar_url,
                            blitz: stats?.blitz_rating ?? 0,
                            rapid: stats?.rapid_rating ?? 0,
                            bullet: stats?.bullet_rating ?? 0,
                            daily: stats?.daily_rating ?? 0,
                            lastGamePlayedAt: lastDate
                        )
                    }

                    await MainActor.run {
                        rows = Array(mergedRefreshed.sorted { valueForRow($0) > valueForRow($1) }.prefix(50))
                    }

                } catch {
                    print("❌ refresh-team-stats invoke failed:", error)
                }
            }

        } catch {
            if isCancellation(error) { return }
            await MainActor.run {
                errorMessage = error.localizedDescription
                rows = []
            }
        }
    }

    func joinTeam() async {
        guard !isJoining else { return }
        let code = joinCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }

        await MainActor.run { isJoining = true }
        defer { Task { @MainActor in isJoining = false } }

        do {
            let team: TeamRow = try await SupabaseManager.shared.supabase
                .from("teams")
                .select("id, name, join_code, slug, created_by")
                .eq("join_code", value: code)
                .single()
                .execute()
                .value

            let session = try await SupabaseManager.shared.supabase.auth.session
            let userId = session.user.id.uuidString

            try await SupabaseManager.shared.supabase
                .from("users")
                .update(["team_id": team.id])
                .eq("id", value: userId)
                .execute()

            await MainActor.run {
                myTeamId = team.id
                myTeamName = team.name
                myTeamJoinCode = team.join_code
            }

            await loadLeaderboard(teamId: team.id)
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    func createTeam() async {
        guard !isCreatingTeam else { return }
        let name = newTeamName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        await MainActor.run { isCreatingTeam = true }
        defer { Task { @MainActor in isCreatingTeam = false } }

        do {
            let session = try await SupabaseManager.shared.supabase.auth.session
            let userId = session.user.id.uuidString

            var created: TeamRow?
            let baseSlug = slugify(name)

            for attempt in 0..<6 {
                let code = generateJoinCode(length: 6)
                let slug = attempt == 0 ? baseSlug : "\(baseSlug)-\(Int.random(in: 10...99))"

                do {
                    let inserted: TeamRow = try await SupabaseManager.shared.supabase
                        .from("teams")
                        .insert([
                            "name": name,
                            "join_code": code,
                            "slug": slug,
                            "created_by": userId
                        ])
                        .select("id, name, join_code, slug, created_by")
                        .single()
                        .execute()
                        .value
                    created = inserted
                    break
                } catch {
                    let msg = error.localizedDescription
                    if looksLikeUniqueViolation(msg) { continue }
                    throw error
                }
            }

            guard let team = created else {
                throw NSError(domain: "CreateTeam", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Could not create a unique team code. Please try again."
                ])
            }

            try await SupabaseManager.shared.supabase
                .from("users")
                .update(["team_id": team.id])
                .eq("id", value: userId)
                .execute()

            await MainActor.run {
                myTeamId = team.id
                myTeamName = team.name
                myTeamJoinCode = team.join_code
                joinCode = team.join_code ?? ""
                newTeamName = ""
            }

            await loadLeaderboard(teamId: team.id)
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    func leaveTeam() async {
        guard hasTeam, !isLeavingTeam else { return }

        await MainActor.run { isLeavingTeam = true }
        defer { Task { @MainActor in isLeavingTeam = false } }

        do {
            let session = try await SupabaseManager.shared.supabase.auth.session
            let userId = session.user.id.uuidString

            struct LeaveTeamPayload: Encodable { let team_id: String? }

            try await SupabaseManager.shared.supabase
                .from("users")
                .update(LeaveTeamPayload(team_id: nil))
                .eq("id", value: userId)
                .execute()

            await MainActor.run {
                myTeamId = nil
                myTeamName = nil
                myTeamJoinCode = nil
                rows = []
                joinCode = ""
                showTeamSheet = false
            }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    func generateJoinCode(length: Int = 6) -> String {
        let chars = Array("ABCDEFGHJKMNPQRSTUVWXYZ23456789")
        return String((0..<length).compactMap { _ in chars.randomElement() })
    }

    func slugify(_ input: String) -> String {
        let lowered = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let allowed = lowered.map { ch -> Character in
            if ch.isLetter || ch.isNumber { return ch }
            return "-"
        }
        let collapsed = String(allowed)
            .replacingOccurrences(of: "-+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return collapsed.isEmpty ? "team" : collapsed
    }

    func looksLikeUniqueViolation(_ message: String) -> Bool {
        let m = message.lowercased()
        return m.contains("duplicate key")
        || m.contains("unique constraint")
        || m.contains("teams_join_code_key")
        || m.contains("teams_slug_key")
    }
}

// MARK: - Preview
#Preview {
    Leaderboard()
        .environmentObject(AuthenticationManager())
}
