import SwiftUI
import Supabase

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false
    @State private var showLoginView = false
    @State private var WelcomeView = false
    @State private var isLoading = true
    @State private var isShowingWelcome = false // ✅ Controls WelcomeScreen
    @State private var isShowingLogin = false   // ✅ Controls LoginView transition
    
    
    var body: some View {
        ZStack {
            ChessboardBackground()
                .ignoresSafeArea()
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Title
                Text("Settings")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                

                
                // About Section
                aboutSection
                    .background(BlurView(style: .systemUltraThinMaterialDark))
                    .cornerRadius(16)
                    .padding(.horizontal)
                
                // Sign Out Button
                signOutSection
            }
            .padding(.top, -300)
            
            
            // Top-right "Done" button overlay
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(16)
            }
            .padding(.top, -400)
        }
        .fullScreenCover(isPresented: $isShowingLogin) {
            LoginView().environmentObject(authManager)
        }
        .fullScreenCover(isPresented: $isShowingWelcome) {
            WelcomeScreen()
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        isShowingWelcome = false
                        isShowingLogin = true
                    }

                }
        }
        .navigationBarHidden(true)
    }
}







// MARK: - Sections
private extension SettingsView {
    var accountSection: some View {
        HStack(spacing: 15) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(authManager.userName)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                Text("Chess.com: \(authManager.chessUsername)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            NavigationLink(destination: AccountDetailsView()) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
    }
    
    var preferencesSection: some View {
        VStack(spacing: 10) {
            ToggleRow(title: "Notifications", isOn: $notificationsEnabled)
            ToggleRow(title: "Dark Mode", isOn: $darkModeEnabled)
        }
        .padding()
    }
    
    var aboutSection: some View {
        VStack(spacing: 10) {
            NavigationLinkRow(title: "App Info", destination: AboutView())
            NavigationLinkRow(title: "Privacy Policy", destination: PrivacyPolicyView())
            NavigationLinkRow(title: "Send Feedback", destination: FeedbackView())
        }
        .padding()
    }
    
    
    var signOutSection: some View {
        Button(action: {
            Task {
                await authManager.logout()
                await MainActor.run {
                    isShowingWelcome = true
                }
            }
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right") // 🔓 Sign-out icon
                    .font(.title2)
                
                Text("Sign Out")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.Maroon, .DarkMaroon]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 110)
        .padding(.top, 20)
    }
}



// MARK: - Components
struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}

struct NavigationLinkRow<Destination: View>: View {
    let title: String
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

    



// MARK: - Placeholder Views

struct AccountDetailsView: View {
    var body: some View {
        Text("Account Details")
            .font(.title2)
            .navigationTitle("Account Details")
    }
}







struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background
            ChessboardBackground()
                .ignoresSafeArea()
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 10) {


                Text("Version 1.0.0")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))

                Text("© 2025 Chess Elo Team")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 5)
            }
            .padding()
            .background(BlurView(style: .systemUltraThinMaterialDark))
            .cornerRadius(16)
            .padding(.horizontal)
            
            // Floating 'Done' button (Top-Right)
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(16)
            }
            .padding(.top, -400)
            .padding(.trailing, 10)
        }
        .navigationBarHidden(true)
    }
}




// MARK: - Reusable Components
private extension AboutView {
    // 📜 Section Title
    func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.white.opacity(0.8))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // ℹ️ Section Text
    func sectionText(_ content: String) -> some View {
        Text(content)
            .font(.body)
            .foregroundColor(.white.opacity(0.85))
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // ⚪ Section Divider
    func sectionDivider() -> some View {
        Divider()
            .background(Color.white.opacity(0.5))
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity)
    }
}




struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background
            ChessboardBackground()
                .ignoresSafeArea()
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Title
                Text("Privacy Policy")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(.top, 20)

                ScrollView {
                    VStack(spacing: 16) {
                        sectionTitle("📜 Last Updated: February 2025")
                        
                        sectionDivider()
                        
                        privacyTextSection(
                            title: "1. Introduction",
                            content: "Welcome to Chess Elo! Your privacy is important to us. This policy outlines how we collect, use, and protect your data while using our app."
                        )

                        privacyTextSection(
                            title: "2. Data Collection",
                            content: "Chess Elo fetches your public chess statistics from Chess.com via their API. This includes your Elo ratings, match history, and performance metrics. We do not store or share your personal data."
                        )

                        privacyTextSection(
                            title: "3. How We Use Your Data",
                            content: """
                            We use your Chess.com stats to:
                            - Display your latest ratings on your lock screen widget.
                            - Provide visual analytics of your chess performance.
                            - Offer insights into your gameplay trends.

                            This data is **read-only** and is not modified or stored on our servers.
                            """
                        )

                        privacyTextSection(
                            title: "4. Third-Party Services",
                            content: """
                            Chess Elo relies on the Chess.com API to access and display your chess stats. Their Privacy Policy governs how your data is managed on their platform.

                            🔗 [Chess.com Privacy Policy](https://www.chess.com/legal/privacy)
                            """
                        )

                        privacyTextSection(
                            title: "5. Data Security",
                            content: """
                            - We do not store user data or Chess.com credentials.
                            - API requests are made securely, and no personal information is saved.
                            - Your app activity remains private and is not shared with third parties.
                            """
                        )

                        privacyTextSection(
                            title: "6. Your Control Over Data",
                            content: "You can stop using Chess Elo at any time. Since we do not store any of your data, no additional action is needed to remove your information."
                        )

                        privacyTextSection(
                            title: "7. Contact Us",
                            content: "If you have any questions about this Privacy Policy, please contact us at: **0121 439 5419**."
                        )
                    }
                    .frame(maxWidth: .infinity) // 🔥 Ensures all sections take full width
                    .padding()
                    .background(BlurView(style: .systemUltraThinMaterialDark)) // 🔥 Glass effect
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            
            // Top-right floating 'Done' button
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(16)
            }
            .padding(.top, -400)
            .padding(.trailing, 10)
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Reusable Components
private extension PrivacyPolicyView {
    // 📜 Section Title
    func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.white.opacity(0.8))
            .frame(maxWidth: .infinity, alignment: .leading) // 🔥 Ensures same width
    }

    // ⚪ Section Divider
    func sectionDivider() -> some View {
        Divider()
            .background(Color.white.opacity(0.5))
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity) // 🔥 Ensures it spans full width
    }

    // 📝 Text Block (Ensuring Same Width)
    func privacyTextSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(content)
                .font(.body)
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading) // 🔥 Ensures all text sections have the same width
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}




struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var feedbackText = ""
    @State private var rating = 0
    @State private var isSubmitting = false
    @State private var showConfirmation = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                ChessboardBackground()
                    .ignoresSafeArea()
                Color.black.opacity(0.7)
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer().frame(height: 80)

                    // App Title & Icon
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white)

                        Text("Feedback")
                            .font(.title) // Change to .largeTitle if you want it even bigger
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }

                    // Rating System
                    VStack {
                        Text("Rate your experience")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))

                        HStack(spacing: 12) {
                            ForEach(1..<6) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .foregroundColor(star <= rating ? .yellow : .gray)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            rating = star
                                        }
                                    }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                    .foregroundColor(.white)

                    // Feedback Input Field
                    TextEditor(text: $feedbackText)
                        .frame(height: 120)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                        )
                        .foregroundColor(.black)
                        .placeholder(when: feedbackText.isEmpty) {
                            Text("Write your feedback here...")
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.leading, 18)
                        }
                        .padding(.horizontal)

                    // Send Feedback Button
                    Button(action: sendFeedback) {
                        ZStack {
                            Text("Submit")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.Maroon, .DarkMaroon]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .opacity(isSubmitting ? 0 : 1)

                            if isSubmitting {
                                ProgressView().tint(.white)
                            }
                        }
                    }
                    .disabled(feedbackText.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                    .opacity(feedbackText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1)
                    .padding(.horizontal)

                    Spacer()
                }

                // Floating 'Done' Button (Top-Right)
                HStack {
                    Spacer()
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(16)
                }
                .padding(.top, -400)
                .padding(.trailing, 10)
            }
            .alert("Thank You!", isPresented: $showConfirmation, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text("Your feedback has been submitted.")
            })
            .alert("Error", isPresented: .constant(errorMessage != nil), actions: {
                Button("OK", role: .cancel) { errorMessage = nil }
            }, message: {
                Text(errorMessage ?? "An unknown error occurred.")
            })
        }
        .navigationBarHidden(true)
    }

    // MARK: - Feedback Submission Logic
    private func sendFeedback() {
        guard !feedbackText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                try await SupabaseManager.shared.supabase
                    .from("feedback")
                    .insert([
                        "feedback_text": feedbackText,
                        "rating": "\(rating)",  // 🔥 Convert Int to String
                        "submitted_at": ISO8601DateFormatter().string(from: Date())
                    ])
                    .execute()

                await MainActor.run {
                    isSubmitting = false
                    showConfirmation = true
                    feedbackText = ""
                    rating = 0
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}




#Preview {
    SettingsView()
        .environmentObject(AuthenticationManager())
}


