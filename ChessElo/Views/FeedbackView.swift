//
//  FeedbackView.swift
//  ChessElo
//
//  Created by Ethan Reid on 19/02/2026.
//


// FeedbackView.swift
import SwiftUI

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var feedbackText = ""
    @State private var rating = 0

    @State private var isSubmitting = false
    @State private var showConfirmation = false
    @State private var showError = false
    @State private var errorMessage: String = ""

    private var trimmedFeedback: String {
        feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        !trimmedFeedback.isEmpty && !isSubmitting
    }

    var body: some View {
        ZStack {
            ChessboardBackground().ignoresSafeArea()
            Color.black.opacity(0.7).ignoresSafeArea()

            VStack(spacing: 14) {
                HStack {
                    Spacer()
                    Button("Done") { dismiss() }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(16)
                }
                .padding(.top, 10)

                VStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white.opacity(0.9))

                    Text("Feedback")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    Text("Help us improve the app with a quick note.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 6)

                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Rate your experience")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                            Spacer()
                            if rating > 0 {
                                Text("\(rating)/5")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.white.opacity(0.75))
                            }
                        }

                        HStack(spacing: 10) {
                            ForEach(1..<6) { star in
                                Button {
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                        rating = star
                                    }
                                } label: {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundColor(star <= rating ? .yellow : .white.opacity(0.35))
                                        .frame(width: 38, height: 38)
                                        .background(Color.white.opacity(star == rating ? 0.10 : 0.06))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(BlurView(style: .systemUltraThinMaterialDark))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your message")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))

                        Text("Tell us what you liked, what felt confusing, or what you want next.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))

                        ZStack(alignment: .topLeading) {
                            if trimmedFeedback.isEmpty {
                                Text("Type your feedback here...")
                                    .foregroundColor(.white.opacity(0.35))
                                    .padding(.top, 12)
                                    .padding(.leading, 10)
                            }

                            TextEditor(text: $feedbackText)
                                .frame(height: 140)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .foregroundColor(.white)
                                .padding(6)
                        }
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(BlurView(style: .systemUltraThinMaterialDark))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))

                    Button(action: sendFeedback) {
                        HStack(spacing: 10) {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "paperplane.fill").font(.headline)
                            }

                            Text(isSubmitting ? "Submitting..." : "Submit Feedback")
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
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Color.black.opacity(0.22), radius: 10, x: 0, y: 6)
                        .opacity(canSubmit ? 1 : 0.55)
                    }
                    .disabled(!canSubmit)
                    .padding(.top, 4)
                }
                .padding(.horizontal)

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .alert("Thank You!", isPresented: $showConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your feedback has been submitted.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private struct FeedbackInsert: Encodable {
        let feedback_text: String
        let rating: Int
        let submitted_at: String
    }

    private func sendFeedback() {
        guard !trimmedFeedback.isEmpty else { return }
        isSubmitting = true

        Task {
            do {
                let payload = FeedbackInsert(
                    feedback_text: trimmedFeedback,
                    rating: rating,
                    submitted_at: ISO8601DateFormatter().string(from: Date())
                )

                try await SupabaseManager.shared.supabase
                    .from("feedback")
                    .insert(payload)
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
                    showError = true
                }
            }
        }
    }
}