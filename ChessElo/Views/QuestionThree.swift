import SwiftUI

public struct QuestionThree: View {
    let onNext: () -> Void  // ✅ Accepts function to move to next step

    enum PlayingStyle: String, CaseIterable, Identifiable {
        case aggressive = "Aggressive"
        case defensive = "Defensive"
        case balanced = "Balanced"
        
        var id: String { rawValue }
    }
    
    @State private var selectedStyle: PlayingStyle = .balanced
    @State private var currentPage: Int = 2  // Page 3 of 5
    
    public var body: some View {
        NavigationStack {
            ZStack {
                ChessboardBackground()
                    .ignoresSafeArea()
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                VStack(spacing: 36) {
                    Text("Playing Style")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("What is your preferred playing style?")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        ForEach(PlayingStyle.allCases) { style in
                            Button(action: {
                                selectedStyle = style
                            }) {
                                HStack(spacing: 12) {
                                    Text(style.rawValue)
                                        .foregroundColor(.white)
                                        .font(.title3.weight(.semibold))
                                    Spacer()
                                    if selectedStyle == style {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.Maroon)
                                            .font(.title3)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedStyle == style ? Color.Maroon : Color.white.opacity(0.2), lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // ✅ Replaced NavigationLink with a Button that triggers `onNext`
                    Button(action: onNext) {
                        Text("Continue")
                            .navigationBarBackButtonHidden(true)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.Maroon, .DarkMaroon]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 4)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.vertical, 40)
                
                VStack {
                    Spacer()
                    PageIndicator(totalPages: 5, currentPage: currentPage)
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("Chess Insight")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
    }
}
