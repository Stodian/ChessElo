import SwiftUI

public struct QuestionFour: View {
    public let onNext: () -> Void

    enum GamesPerMonth: String, CaseIterable, Identifiable {
        case lessThan5 = "Less than 5"
        case fiveToTen = "5 - 10"
        case tenToTwenty = "10 - 20"
        case moreThan20 = "More than 20"

        var id: String { rawValue }
    }

    @State private var selectedGames: GamesPerMonth = .lessThan5

    public init(onNext: @escaping () -> Void) {
        self.onNext = onNext
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            ChessboardBackground()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.85),
                    Color.black.opacity(0.65)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            content
                .padding(.bottom, 54) // leave room for the indicator

            // ✅ Bottom pinned page indicator (no safeAreaInset)
            PageIndicator(totalPages: 5, currentPage: 3)
                .padding(.bottom, 14)
        }
        .navigationTitle("Chess Insight")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }

    private var content: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 10)

            VStack(spacing: 10) {
                Text("Game Frequency")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("How many games do you play per month?")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.top, 10)

            VStack(spacing: 12) {
                ForEach(GamesPerMonth.allCases) { option in
                    optionRow(option)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)

            Button(action: onNext) {
                HStack {
                    Text("Continue")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.headline)
                }
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
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 6)
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)

            Spacer()
        }
        .padding(.top, 18)
    }

    private func optionRow(_ option: GamesPerMonth) -> some View {
        let isSelected = selectedGames == option

        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                selectedGames = option
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.rawValue)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)

                    Text(isSelected ? "Selected" : "Tap to select")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .Maroon : .white.opacity(0.35))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.10 : 0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.Maroon.opacity(0.9) : Color.white.opacity(0.10), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
