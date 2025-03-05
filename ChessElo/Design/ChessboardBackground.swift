import SwiftUI

struct ChessboardBackground: View {
    let squareSize: CGFloat = 50
    
    var body: some View {
        ZStack {
            // Deep maroon base color
            Color(red: 0.4, green: 0.1, blue: 0.4)
                .ignoresSafeArea()
            
            // Checkered pattern
            GeometryReader { geometry in
                let columns = Int(ceil(geometry.size.width / squareSize))
                let rows = Int(ceil(geometry.size.height / squareSize))
                
                Path { path in
                    for row in 0..<rows {
                        for col in 0..<columns {
                            if (row + col).isMultiple(of: 2) {
                                let rect = CGRect(x: CGFloat(col) * squareSize,
                                                y: CGFloat(row) * squareSize,
                                                width: squareSize,
                                                height: squareSize)
                                path.addRect(rect)
                            }
                        }
                    }
                }
                .fill(Color.black.opacity(0.2))
            }
        }
        .ignoresSafeArea()
    }
} 
