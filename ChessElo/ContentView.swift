import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isAuthenticated = false

    var body: some View {
        NavigationView {
            if authManager.isAuthenticated {
                ChessStatsView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            Task {
                await checkSession()
            }
        }
    }
    
    func checkSession() async {
        await authManager.restoreSession()
        
        // Update local state based on auth manager
        isAuthenticated = authManager.isAuthenticated
    }
}

#Preview {
    WelcomeScreen()
        .environmentObject(AuthenticationManager())
}
