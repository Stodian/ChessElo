// ChessEloApp.swift
import SwiftUI

@main
struct ChessEloApp: App {
    @StateObject private var authManager = AuthenticationManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                // ✅ Handle Supabase email-confirm deep links like:
                // chesselo://auth-callback#access_token=...
                .onOpenURL { url in
                    Task {
                        do {
                            // ✅ NEW Supabase Swift: handle incoming auth callback URL
                            try await SupabaseManager.shared.supabase.auth.handle(url)

                            // ✅ Refresh app state after the session is stored
                            await authManager.restoreSession()
                        } catch {
                            print("❌ auth.handle(url:) failed:", String(reflecting: error))
                        }
                    }
                }
        }
    }
}

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    @State private var isShowingWelcome = true
    @State private var onboardingCompleted: Bool = UserDefaults.standard.bool(forKey: "onboardingCompleted")

    // Optional debug overlay
    @State private var navigationState: String = "Initial"

    var body: some View {
        ZStack {

            // ✅ 1) Always wait for restore to finish first (prevents flicker)
            if authManager.isRestoring {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Checking session...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .onAppear { navigationState = "Restoring Session" }
            }

            // ✅ 2) If authenticated, skip Welcome entirely
            else if authManager.isAuthenticated {
                NavigationStack {
                    ChessStatsView()
                }
                .transition(.opacity)
                .onAppear { navigationState = "Stats Screen" }
            }

            // ✅ 3) Not authenticated: show Welcome once, then proceed
            else if isShowingWelcome {
                WelcomeScreen {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isShowingWelcome = false
                    }
                }
                .transition(.opacity)
                .onAppear { navigationState = "Welcome Screen" }
            }

            // ✅ 4) After Welcome: onboarding then login
            else if !onboardingCompleted {
                OnboardingFlowView(onCompletion: {
                    navigationState = "After Onboarding"
                    onboardingCompleted = true
                    UserDefaults.standard.set(true, forKey: "onboardingCompleted")
                })
                .transition(.opacity)
            }

            else {
                LoginView()
                    .transition(.opacity)
                    .onAppear { navigationState = "Login Screen" }
            }

        }
        // ✅ Ensure Welcome doesn't "stick" if auth becomes true later (e.g. deep link / restore)
        .onChange(of: authManager.isAuthenticated) { authed in
            if authed { isShowingWelcome = false }
        }
    }
}
