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
    @State private var isShowingWelcome = true
    @State private var isShowingLogin = false
    @State private var onboardingCompleted: Bool = UserDefaults.standard.bool(forKey: "onboardingCompleted")
    
    // For debugging
    @State private var navigationState: String = "Initial"

    var body: some View {
        ZStack {
            if isShowingWelcome {
                // Show welcome screen
                WelcomeScreen()
                    .transition(.opacity)
                    .onAppear {
                        print("📱 Showing Welcome Screen")
                        navigationState = "Welcome Screen"
                        
                        // Set a timer to transition after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            print("📱 Welcome screen timeout - transitioning...")
                            navigationState = "After Welcome"
                            
                            withAnimation(.easeInOut(duration: 0.5)) {
                                isShowingWelcome = false
                            }
                        }
                    }
            } else if !onboardingCompleted {
                // Show onboarding flow if not completed
                OnboardingFlowView(onCompletion: {
                    print("📱 Onboarding completed")
                    navigationState = "After Onboarding"
                    
                    onboardingCompleted = true
                    UserDefaults.standard.set(true, forKey: "onboardingCompleted")
                    
                    withAnimation(.easeInOut) {
                        isShowingLogin = !authManager.isAuthenticated
                    }
                })
                .transition(.opacity)
            } else if !authManager.isAuthenticated {
                // Show login if not authenticated
                LoginView()
                    .transition(.opacity)
                    .onAppear {
                        print("📱 Showing Login Screen")
                        navigationState = "Login Screen"
                    }
            } else {
                // Show main app view if authenticated
                ChessStatsView()
                    .transition(.opacity)
                    .onAppear {
                        print("📱 Showing Stats Screen")
                        navigationState = "Stats Screen"
                    }
            }
            
            // Optional debug overlay - comment out for production
            VStack {
                Spacer()
                Text("State: \(navigationState)")
                    .font(.caption)
                    .padding(5)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(5)
            }
            .padding()
        }
        .onAppear {
            // Initialize authentication state when the RootView appears
            Task {
                print("📱 RootView appeared - checking session")
                await authManager.restoreSession()
                
                // Wait for session restoration to complete before updating UI
                await MainActor.run {
                    print("📱 Session check complete - auth state: \(authManager.isAuthenticated)")
                    
                    // If already showing welcome, don't change states yet
                    if !isShowingWelcome {
                        if onboardingCompleted {
                            isShowingLogin = !authManager.isAuthenticated
                        }
                    }
                }
            }
        }
    }
}
