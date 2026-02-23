//
//  AboutView.swift
//  ChessElo
//
//  Created by Ethan Reid on 19/02/2026.
//


// AboutView.swift
import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            ChessboardBackground().ignoresSafeArea()
            Color.black.opacity(0.7).ignoresSafeArea()

            VStack(spacing: 10) {
                Text("Version 1.0.0")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))

                Text("© 2026 Chess Elo Team")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 5)
            }
            .padding()
            .background(BlurView(style: .systemUltraThinMaterialDark))
            .cornerRadius(16)
            .padding(.horizontal)

            VStack {
                HStack {
                    Spacer()
                    Button("Done") { dismiss() }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(16)
                }
                Spacer()
            }
            .padding(.top, 10)
        }
        .navigationBarHidden(true)
    }
}
