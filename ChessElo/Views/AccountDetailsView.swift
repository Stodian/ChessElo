//
//  AccountDetailsView.swift
//  ChessElo
//
//  Created by Ethan Reid on 19/02/2026.
//

import SwiftUI
import Supabase

struct AccountDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager

    @State private var displayName: String = ""

    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showSaved = false

    private struct ProfileRow: Decodable {
        let display_name: String?
        let chess_username: String?
    }

    private struct UpsertUserRow: Encodable {
        let id: String
        let email: String
        let display_name: String
        // ✅ chess_username removed (read-only now)
    }

    var body: some View {
        ZStack {
            ChessboardBackground().ignoresSafeArea()
            Color.black.opacity(0.7).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Spacer(minLength: 18)

                    Text("Account")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    VStack(spacing: 12) {
                        infoRow(title: "Email", value: authManager.email.isEmpty ? "—" : authManager.email)

                        // ✅ Read-only Chess.com username
                        infoRow(
                            title: "Chess.com Username",
                            value: authManager.chessUsername.isEmpty ? "—" : authManager.chessUsername
                        )

                        // ✅ Only editable field
                        fieldCard(title: "Display Name", placeholder: "Your name", text: $displayName)
                    }
                    .padding()
                    .background(BlurView(style: .systemUltraThinMaterialDark))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            .padding(.horizontal)
                    )

                    Button { Task { await save() } } label: {
                        HStack {
                            if isSaving { ProgressView().tint(.white) }
                            Text(isSaving ? "Saving..." : "Save Changes")
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
                        .opacity(isSaving ? 0.8 : 1)
                    }
                    .disabled(isSaving || isLoading)
                    .padding(.horizontal)

                    Spacer(minLength: 30)
                }
                .padding(.bottom, 20)
            }

            // Done button
            VStack {
                HStack {
                    Spacer()
                    Button("Done") { dismiss() }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(16)
                }
                Spacer()
            }
            .padding(.top, 10)

            // Loading overlay
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView().tint(.white)
                    Text("Loading...")
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(BlurView(style: .systemUltraThinMaterialDark))
                .cornerRadius(14)
            }
        }
        .navigationBarHidden(true)
        .onAppear { Task { await load() } }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
        .alert("Saved", isPresented: $showSaved) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your account details have been updated.")
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.trailing)
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func fieldCard(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))

            TextField(placeholder, text: text)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled(true)
                .padding()
                .background(Color.white.opacity(0.10))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func load() async {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }

        do {
            let session = try await SupabaseManager.shared.supabase.auth.session
            let userId = session.user.id.uuidString

            let row: ProfileRow = try await SupabaseManager.shared.supabase
                .from("users")
                .select("display_name, chess_username")
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            let dbDisplay = row.display_name ?? ""

            await MainActor.run {
                self.displayName = dbDisplay.isEmpty ? authManager.displayName : dbDisplay
                // chess username comes from authManager and is shown read-only
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                displayName = authManager.displayName
            }
        }
    }

    private func save() async {
        guard !isSaving else { return }
        await MainActor.run { isSaving = true }
        defer { Task { @MainActor in isSaving = false } }

        do {
            let session = try await SupabaseManager.shared.supabase.auth.session
            let userId = session.user.id.uuidString

            let trimmedDisplay = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

            let payload = UpsertUserRow(
                id: userId,
                email: authManager.email,
                display_name: trimmedDisplay
            )

            try await SupabaseManager.shared.supabase
                .from("users")
                .upsert(payload, onConflict: "id")
                .execute()

            await MainActor.run {
                authManager.displayName = trimmedDisplay
                showSaved = true
            }

            // refresh avatar + fields from DB/auth (username stays as-is)
            await authManager.refreshProfile()

        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
