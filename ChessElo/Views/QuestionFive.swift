import SwiftUI

public struct QuestionFive: View {
    let onNext: () -> Void  // ✅ Accepts function to move to the next step

    enum CoachingPreference: String, CaseIterable, Identifiable {
        case yes = "Yes"
        case no = "No"
        case maybe = "Maybe"
        
        var id: String { rawValue }
    }
    
    @State private var selectedPreference: CoachingPreference = .yes
    @State private var currentPage: Int = 4  // Page 5 of 5
    
    public var body: some View {
        NavigationStack {
            ZStack {
                ChessboardBackground()
                    .ignoresSafeArea()
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                VStack(spacing: 36) {
                    Text("Coaching Tips")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Would you like personalized coaching tips?")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        ForEach(CoachingPreference.allCases) { option in
                            Button(action: {
                                selectedPreference = option
                            }) {
                                HStack(spacing: 12) {
                                    Text(option.rawValue)
                                        .foregroundColor(.white)
                                        .font(.title3.weight(.semibold))
                                    Spacer()
                                    if selectedPreference == option {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.Maroon)
                                            .font(.title3)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedPreference == option ? Color.Maroon : Color.white.opacity(0.2), lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // ✅ Replaced NavigationLink with a Button that triggers `onNext`
                    Button(action: onNext) {
                        Text("Finish")
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
