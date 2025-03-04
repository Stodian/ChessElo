import SwiftUI

struct EditUsernameView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var username: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Chess.com Username", text: $username)
            }
            .navigationTitle("Edit Username")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if !username.isEmpty {
                            authManager.updateUsername(username)
                        }
                        dismiss()
                    }
                    .disabled(username.isEmpty)
                }
            }
            .onAppear {
                username = authManager.chessUsername
            }
        }
    }
}

#Preview {
    EditUsernameView()
        .environmentObject(AuthenticationManager())
}

