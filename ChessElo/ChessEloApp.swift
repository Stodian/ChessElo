import SwiftUI

@main
struct ChessEloApp: App {
    @StateObject private var authManager = AuthenticationManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
        }
    }
}



import SwiftUI

struct RootView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isShowingWelcome = true  // ✅ Show WelcomeScreen first
    @State private var isShowingLogin = false  // ✅ Control LoginView transition
    @State private var onboardingCompleted: Bool = UserDefaults.standard.bool(forKey: "onboardingCompleted")

    var body: some View {
        Group {
            if isShowingWelcome {
                WelcomeScreen()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            isShowingWelcome = false
                            if !onboardingCompleted {
                                isShowingLogin = false
                            } else {
                                isShowingLogin = !authManager.isAuthenticated
                            }
                        }
                    }
            } else if !onboardingCompleted {
                OnboardingFlowView(onCompletion: {
                    onboardingCompleted = true
                    UserDefaults.standard.set(true, forKey: "onboardingCompleted")
                    isShowingLogin = true
                })
            } else if isShowingLogin {
                LoginView()
            } else if authManager.isAuthenticated {
                ChessStatsView()
            } else {
                WelcomeScreen() // Fallback in case of issues
            }
        }
        .onAppear {
            Task {
                await authManager.restoreSession()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    isShowingWelcome = false
                    if !onboardingCompleted {
                        isShowingLogin = false
                    } else {
                        isShowingLogin = !authManager.isAuthenticated
                    }
                }
            }
        }
    }
}
