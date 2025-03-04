import SwiftUI

public struct QuestionTwo: View {
    let onNext: () -> Void  // ✅ Accepts function to move to next step

    enum Frequency: String, CaseIterable, Identifiable {
        case daily = "Daily"
        case severalTimes = "Several Times a Week"
        case weekly = "Weekly"
        case rarely = "Rarely"
        
        var id: String { rawValue }
    }
    
    @State private var selectedFrequency: Frequency = .daily
    @State private var currentPage: Int = 1  // Page 2 of 5
    
    public var body: some View {
        NavigationStack {
            ZStack {
                ChessboardBackground()
                    .ignoresSafeArea()
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                VStack(spacing: 36) {
                    Text("Puzzle Practice")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("How often do you practice chess puzzles?")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        ForEach(Frequency.allCases) { option in
                            Button(action: {
                                selectedFrequency = option
                            }) {
                                HStack(spacing: 12) {
                                    Text(option.rawValue)
                                        .foregroundColor(.white)
                                        .font(.title3.weight(.semibold))
                                    Spacer()
                                    if selectedFrequency == option {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.Maroon)
                                            .font(.title3)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedFrequency == option ? Color.Maroon : Color.white.opacity(0.2), lineWidth: 2)
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
