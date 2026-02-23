import SwiftUI
import UIKit

// MARK: - Custom Theme Colors
extension Color {
    static let Maroon = Color(red: 128/255, green: 0, blue: 0)
    static let DarkMaroon = Color(red: 64/255, green: 0, blue: 0)
    static let Ink = Color(red: 10/255, green: 10/255, blue: 12/255)
}

// MARK: - WelcomeScreen (Premium)
struct WelcomeScreen: View {

    /// Call this when the user taps Get Started
    let onContinue: () -> Void

    // Animation state
    @State private var appear = false
    @State private var glow = false
    @State private var pulse = false

    /// ✅ Disabled: only move forward on button tap
    var autoContinueAfterSeconds: Double? = nil

    var body: some View {
        ZStack {
            // Background
            ChessboardBackground()
                .ignoresSafeArea()
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.80),
                            Color.black.opacity(0.72),
                            Color.black.opacity(0.86)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
                .overlay(premiumAccentGlow.opacity(appear ? 1 : 0))

            VStack(spacing: 0) {

                Spacer(minLength: 20)

                hero

                Spacer(minLength: 22)

                actionArea

                Spacer(minLength: 26)

                footer
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 22)
        }
        .onAppear {
            runEntrance()
        }
    }
}

// MARK: - Sections
private extension WelcomeScreen {

    var hero: some View {
        VStack(spacing: 18) {

            // Icon + halo
            ZStack {
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 94, height: 94)
                    .overlay(
                        Circle().stroke(.white.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.Maroon.opacity(glow ? 0.55 : 0.35),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 4,
                            endRadius: 60
                        )
                    )
                    .frame(width: 110, height: 110)
                    .blur(radius: 2)
                    .opacity(appear ? 1 : 0)

                Image(systemName: "checkerboard.rectangle")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 6)
            }
            .scaleEffect(appear ? (pulse ? 1.02 : 1.0) : 0.92)
            .opacity(appear ? 1 : 0)
            .animation(.spring(response: 0.55, dampingFraction: 0.78), value: appear)
            .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulse)

            // Title
            VStack(spacing: 10) {
                Text("ChessElo")
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .tracking(0.5)
                    .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)
                    .overlay(
                        LinearGradient(
                            colors: [.white.opacity(0.35), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .blendMode(.overlay)
                    )

                Text("Your chess ratings — instantly.\nBeautiful widgets. Clean insights.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.80))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 10)
            .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.05), value: appear)

            // Glass feature card
            VStack(alignment: .leading, spacing: 12) {
                featureRow(
                    icon: "bolt.fill",
                    title: "Fast refresh",
                    subtitle: "Pull ratings from Chess.com in seconds."
                )

                featureRow(
                    icon: "rectangle.3.offgrid",
                    title: "Widgets",
                    subtitle: "Lock screen + Home screen layouts."
                )

                // ✅ Updated: friends / groups comparison
                featureRow(
                    icon: "person.3.fill",
                    title: "Compare with friends",
                    subtitle: "Join groups to track ratings and see who’s improving fastest."
                )
            }
            .padding(16)
            .background(glassCard)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.10), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 14)
            .animation(.spring(response: 0.75, dampingFraction: 0.85).delay(0.12), value: appear)
        }
    }

    var actionArea: some View {
        VStack(spacing: 12) {

            Button {
                haptic(.medium)
                onContinue()
            } label: {
                HStack(spacing: 10) {
                    Text("Get Started")
                        .font(.system(size: 17, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.Maroon, Color.DarkMaroon],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.Maroon.opacity(0.35), radius: 18, x: 0, y: 10)
            }
            .buttonStyle(.plain)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 10)
            .animation(.spring(response: 0.65, dampingFraction: 0.85).delay(0.18), value: appear)

            Text("By continuing, you agree to our Privacy Policy.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .opacity(appear ? 1 : 0)
                .animation(.easeOut(duration: 0.35).delay(0.25), value: appear)
        }
    }

    var footer: some View {
        HStack(spacing: 8) {
            Circle().fill(.white.opacity(0.22)).frame(width: 6, height: 6)
            Text("v1.0 • Built for quick stats")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.55))
            Circle().fill(.white.opacity(0.22)).frame(width: 6, height: 6)
        }
        .opacity(appear ? 1 : 0)
        .animation(.easeOut(duration: 0.35).delay(0.28), value: appear)
    }

    func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.Maroon.opacity(0.95))
                .frame(width: 22, height: 22)
                .padding(8)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.92))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Styling helpers
private extension WelcomeScreen {

    var glassCard: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(.ultraThinMaterial.opacity(0.65))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.14), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.overlay)
            )
    }

    var premiumAccentGlow: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.Maroon.opacity(0.35),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 10,
                        endRadius: 260
                    )
                )
                .offset(y: -220)
                .blur(radius: 8)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.06),
                            Color.clear
                        ],
                        center: .bottom,
                        startRadius: 10,
                        endRadius: 240
                    )
                )
                .offset(y: 260)
                .blur(radius: 10)
        }
        .allowsHitTesting(false)
    }

    func runEntrance() {
        appear = false
        glow = false
        pulse = false

        withAnimation(.spring(response: 0.85, dampingFraction: 0.85)) {
            appear = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            glow = true
            pulse = true
        }
    }

    func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Preview
#Preview {
    WelcomeScreen(onContinue: {})
        .environmentObject(AuthenticationManager())
}
