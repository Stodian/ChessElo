//
//  PrivacyPolicyView.swift
//  ChessElo
//
//  Created by Ethan Reid on 19/02/2026.
//


// PrivacyPolicyView.swift
import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    private let lastUpdated = "February 2026"

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

                VStack(spacing: 10) {
                    Text("Privacy Policy")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, -50)

                    Text("Last updated: \(lastUpdated)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, -25)
                }
                .padding(.top, 4)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        policyCard(title: "1. Introduction",
                                   body: "Welcome to Chess Elo. Your privacy is important to us. This policy explains what we collect, how we use it, and how we protect it.")
                        policyCard(title: "2. Data We Use",
                                   body: "Chess Elo fetches your public chess statistics from Chess.com via their public API, such as ratings and performance data.")
                        policyCard(title: "3. How We Use It",
                                   body: "We use your Chess.com stats to display your ratings, power widgets, and show performance insights. This data is read-only.")
                        policyCard(title: "4. Third-Party Services",
                                   body: "Chess Elo relies on the Chess.com API. Your Chess.com account remains governed by Chess.com’s own terms and privacy policy.")
                        policyCard(title: "5. Contact",
                                   body: "If you have any questions, contact: ethan@stodian.uk")
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private func policyCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline).foregroundColor(.white)
            Text(body)
                .font(.body)
                .foregroundColor(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BlurView(style: .systemUltraThinMaterialDark))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}
