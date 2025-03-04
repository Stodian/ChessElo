import SwiftUI

public struct QuestionOne: View {
    let onNext: () -> Void  // ✅ Accepts function to move to next step

    enum ChessArea: String, CaseIterable, Identifiable {
        case openings = "Openings"
        case tactics = "Tactics"
        case middlegame = "Middlegame"
        case endgame = "Endgame"
        case strategy = "Strategy"
        
        var id: String { rawValue }
        
        var iconName: String {
            switch self {
            case .openings: return "book.fill"
            case .tactics: return "bolt.fill"
            case .middlegame: return "figure.walk"
            case .endgame: return "hourglass.bottomhalf.fill"
            case .strategy: return "brain.head.profile"
            }
        }
    }
    
    @State private var selectedArea: ChessArea = .openings
    @State private var currentPage: Int = 0  // Page index for question 1 of 5
    
    public var body: some View {
        NavigationStack {
            ZStack {
                ChessboardBackground()
                    .ignoresSafeArea()
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                VStack(spacing: 36) {
                    Text("Chess Insight")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Which area of your chess game would you most like to improve?")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Vertical selection list.
                    VStack(spacing: 16) {
                        ForEach(ChessArea.allCases) { area in
                            Button(action: {
                                selectedArea = area
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: area.iconName)
                                        .foregroundColor(.white)
                                        .font(.title3)
                                    Text(area.rawValue)
                                        .foregroundColor(.white)
                                        .font(.title3.weight(.semibold))
                                    Spacer()
                                    if selectedArea == area {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.Maroon)
                                            .font(.title3)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedArea == area ? Color.Maroon : Color.white.opacity(0.2), lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Next button triggers onNext() instead of using NavigationLink
                    Button(action: onNext) {
                        Text("I'm Ready to Improve")
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
                    
                    Spacer(minLength: 20)
                }
                .padding(.vertical, 40)
                
                // Page indicator at the bottom.
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
