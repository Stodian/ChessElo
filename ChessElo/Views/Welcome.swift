import SwiftUI

// MARK: - Custom Theme Colors
extension Color {
    static let Maroon = Color(red: 128/255, green: 0, blue: 0)
    static let DarkMaroon = Color(red: 64/255, green: 0, blue: 0)
}

struct WelcomeScreen: View {
    @State private var animateLetters = false
    @State private var shouldNavigate = false
    private let titleText = "Chess Elo"
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background: Custom chessboard image with a dark overlay.
                ChessboardBackground()
                    .ignoresSafeArea()
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // Animated Title: Each letter animates in sequentially.
                    HStack(spacing: 0) {
                        ForEach(Array(titleText.enumerated()), id: \.offset) { index, character in
                            Text(String(character))
                                .font(.system(size: 80, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .opacity(animateLetters ? 1 : 0)
                                .scaleEffect(animateLetters ? 1 : 0.5)
                                .animation(
                                    .easeOut(duration: 0.8).delay(Double(index) * 0.2),
                                    value: animateLetters
                                )
                        }
                    }
                    
                    // Tagline
                    Text("Elevate Your Game With Expert Insights")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.top, 0)
                        .padding(.horizontal)
                    
                    Spacer()
                }
                
                // Hidden NavigationLink to automatically navigate after 3 seconds.
                NavigationLink(destination: QuestionOne(onNext: { shouldNavigate = false })) {
                    EmptyView()
                }
            }
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .onAppear {
                animateLetters = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    shouldNavigate = true
                }
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $shouldNavigate) {
            QuestionOne(onNext: { shouldNavigate = false }) // ✅ Fix: Provide required argument
        }
    }
}



// MARK: - PageIndicator Component
struct PageIndicator: View {
    let totalPages: Int
    let currentPage: Int  // 0-based index
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.Maroon : Color.white.opacity(0.3))
                    .frame(width: 12, height: 12)
            }
        }
    }
}




#Preview {
    WelcomeScreen()
        .environmentObject(AuthenticationManager()) // ✅ Correct syntax
}
