//
//  PageIndicator.swift
//  ChessElo
//
//  Created by Ethan Reid on 20/02/2026.
//


import SwiftUI

struct PageIndicator: View {
    let totalPages: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.Maroon : Color.white.opacity(0.25))
                    .frame(width: index == currentPage ? 18 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial, in: Capsule())
    }
}