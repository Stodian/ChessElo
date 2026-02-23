//
//  SettingsView.swift
//  ChessElo
//

import SwiftUI
import Supabase
import UIKit

// MARK: - Delete User Models
private struct DeleteUserRequest: Encodable {
    let confirm: Bool
}

private struct DeleteUserResponse: Decodable {
    let ok: Bool
    let message: String?
    let userId: String?
    let error: String?
    let details: String?
}

// MARK: - SettingsView
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager

    // ✅ Supabase anon key (only needed if you call Edge Functions manually with URLSession)
    private let supabaseAnonKey =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN1amVqYmlla3ZqemVyeG5zbGNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE0Mzc1MTMsImV4cCI6MjA4NzAxMzUxM30.QMNwYUgQYG5-cRiiBdkUsm2Lz9N85d_1gpsp0PCA9zw"

    // UX state
    @State private var isDeletingAccount = false
    @State private var showDeleteConfirm = false
    @State private var showDeleteResult = false
    @State private var deleteResultMessage: String = ""
    @State private var deleteResultIsError = false

    var body: some View {
        ZStack {
            ChessboardBackground().ignoresSafeArea()
            Color.black.opacity(0.70).ignoresSafeArea()

            VStack(spacing: 14) {
                headerBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {

                        // Profile / Account card (matches your glass cards)
                        NavigationLink(destination: AccountDetailsView().environmentObject(authManager)) {
                            accountCard
                        }
                        .buttonStyle(.plain)

                        // About
                        glassCard(title: "About") {
                            VStack(spacing: 10) {
                                NavigationLinkRow(title: "App Info", destination: AboutView())
                                NavigationLinkRow(title: "Privacy Policy", destination: PrivacyPolicyView())
                                NavigationLinkRow(title: "Send Feedback", destination: FeedbackView())
                            }
                        }

                        // Danger zone
                        dangerCard

                        // Sign out (centered button like your other pages)
                        signOutButton

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
            }

            // Blocking overlay while deleting (same style as Leaderboard loading overlay)
            if isDeletingAccount {
                Color.black.opacity(0.35).ignoresSafeArea()

                VStack(spacing: 12) {
                    ProgressView().tint(.white)
                    Text("Deleting account...")
                        .foregroundColor(.white.opacity(0.90))
                        .font(.headline)
                    Text("Please don’t close the app.")
                        .foregroundColor(.white.opacity(0.70))
                        .font(.caption)
                }
                .padding(18)
                .background(BlurView(style: .systemUltraThinMaterialDark))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
                .padding()
            }
        }
        .navigationBarHidden(true)
        .alert("Delete Account?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await deleteAccount() }
            }
        } message: {
            Text("This will permanently delete your account data and sign you out. This cannot be undone.")
        }
        .alert(deleteResultIsError ? "Error" : "Done", isPresented: $showDeleteResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteResultMessage)
        }
    }
}

// MARK: - Header Bar (matches your other pages)
private extension SettingsView {
    var headerBar: some View {
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

            Text("Settings")
                .font(.title2.bold())
                .foregroundColor(.white)

            Spacer()

            // Right side placeholder to keep the title centered (like your Leaderboard)
            Image(systemName: "chevron.left")
                .font(.title3.weight(.semibold))
                .foregroundColor(.clear)
                .padding(10)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }
}

// MARK: - Cards / Rows
private extension SettingsView {

    var accountCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                avatarView(urlString: authManager.chessAvatarURL)

                VStack(alignment: .leading, spacing: 4) {
                    Text(authManager.displayName.isEmpty ? "Signed in" : authManager.displayName)
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Text("Chess.com: \(authManager.chessUsername.isEmpty ? "Not set" : authManager.chessUsername)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.70))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.70))
            }
        }
        .padding(14)
        .background(BlurView(style: .systemUltraThinMaterialDark))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    var dangerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Danger Zone")
                .font(.headline)
                .foregroundColor(.white.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Delete your account and associated data.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.65))
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                showDeleteConfirm = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "trash")
                        .font(.title3)

                    Text(isDeletingAccount ? "Deleting..." : "Delete Account")
                        .font(.headline)

                    Spacer()

                    if isDeletingAccount { ProgressView().tint(.white) }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.35), lineWidth: 1)
                )
                .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .disabled(isDeletingAccount)
            .opacity(isDeletingAccount ? 0.7 : 1.0)
        }
        .padding(14)
        .background(BlurView(style: .systemUltraThinMaterialDark))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.22), lineWidth: 1)
        )
    }

    var signOutButton: some View {
        Button {
            Task { await authManager.logout() }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.title3.weight(.semibold))
                Text("Sign Out")
                    .font(.headline)
            }
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
            .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 60)
        .padding(.top, 8)
    }

    func glassCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)

            content()
        }
        .padding(14)
        .background(BlurView(style: .systemUltraThinMaterialDark))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    func avatarView(urlString: String?) -> some View {
        Group {
            if let s = urlString, !s.isEmpty, let url = URL(string: s) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().tint(.white.opacity(0.85))
                            .frame(width: 52, height: 52)
                    case .success(let image):
                        image.resizable()
                            .scaledToFill()
                            .frame(width: 52, height: 52)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.35), radius: 6, x: 0, y: 3)
                    default:
                        Circle()
                            .fill(Color.white.opacity(0.10))
                            .frame(width: 52, height: 52)
                            .overlay(Image(systemName: "person.fill").foregroundColor(.white.opacity(0.75)))
                    }
                }
            } else {
                Circle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 52, height: 52)
                    .overlay(Image(systemName: "person.fill").foregroundColor(.white.opacity(0.75)))
            }
        }
    }
}

// MARK: - Delete Account Logic
private extension SettingsView {

    func deleteAccount() async {
        guard !isDeletingAccount else { return }

        await MainActor.run {
            isDeletingAccount = true
            deleteResultIsError = false
            deleteResultMessage = ""
        }

        defer { Task { @MainActor in isDeletingAccount = false } }

        do {
            // Keep session fresh
            _ = try await SupabaseManager.shared.supabase.auth.refreshSession()
            let session = try await SupabaseManager.shared.supabase.auth.session
            let accessToken = session.accessToken

            // Call Edge Function directly
            let url = URL(string: "https://cujejbiekvjzerxnslcq.supabase.co/functions/v1/delete-user")!
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            req.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            req.httpBody = try JSONEncoder().encode(DeleteUserRequest(confirm: true))

            let (data, resp) = try await URLSession.shared.data(for: req)
            let status = (resp as? HTTPURLResponse)?.statusCode ?? -1
            let rawBody = String(data: data, encoding: .utf8) ?? "<no body>"

            let decoded = try? JSONDecoder().decode(DeleteUserResponse.self, from: data)

            guard (200...299).contains(status), decoded?.ok == true else {
                let msg = decoded?.error ?? decoded?.message ?? "Delete failed"
                let det = decoded?.details ?? rawBody
                throw NSError(
                    domain: "DeleteUser",
                    code: status,
                    userInfo: [NSLocalizedDescriptionKey: "\(msg) (\(status))\n\(det)"]
                )
            }

            // Sign out locally
            await authManager.logout()

            await MainActor.run {
                deleteResultMessage = "Your account has been permanently deleted."
                deleteResultIsError = false
                showDeleteResult = true
            }
        } catch {
            await MainActor.run {
                deleteResultMessage = error.localizedDescription
                deleteResultIsError = true
                showDeleteResult = true
            }
            print("❌ delete failed:", String(reflecting: error))
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(AuthenticationManager())
}
