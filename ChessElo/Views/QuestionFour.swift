import SwiftUI

public struct QuestionFour: View {
    let onNext: () -> Void  // ✅ Accepts function to move to next step

    enum GamesPerMonth: String, CaseIterable, Identifiable {
        case lessThan5 = "Less than 5"
        case fiveToTen = "5 - 10"
        case tenToTwenty = "10 - 20"
        case moreThan20 = "More than 20"
        
        var id: String { rawValue }
    }
    
    @State private var selectedGames: GamesPerMonth = .lessThan5
    @State private var currentPage: Int = 3  // Page 4 of 5
    
    public var body: some View {
        NavigationStack {
            ZStack {
                ChessboardBackground()
                    .ignoresSafeArea()
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                VStack(spacing: 36) {
                    Text("Game Frequency")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("How many games do you play per month?")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        ForEach(GamesPerMonth.allCases) { option in
                            Button(action: {
                                selectedGames = option
                            }) {
                                HStack(spacing: 12) {
                                    Text(option.rawValue)
                                        .foregroundColor(.white)
                                        .font(.title3.weight(.semibold))
                                    Spacer()
                                    if selectedGames == option {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.Maroon)
                                            .font(.title3)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedGames == option ? Color.Maroon : Color.white.opacity(0.2), lineWidth: 2)
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
