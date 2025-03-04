import SwiftUI

struct ContentView: View {
    @State private var isAuthenticated = false

    var body: some View {
        NavigationView {
            if isAuthenticated {
                ChessStatsView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            checkSession()
        }
    }
    
    
    struct ContentView: View {
        @EnvironmentObject var authManager: AuthenticationManager

        var body: some View {
            if authManager.isAuthenticated {
                ChessStatsView()
            } else {
                LoginView()
            }
        }
    }
    

    func checkSession() {
        Task {
            if let _ = try? await SupabaseManager.shared.supabase.auth.session {
                isAuthenticated = true
            }
        }
    }
}

#Preview {
    WelcomeScreen()
        .environmentObject(AuthenticationManager())
}
