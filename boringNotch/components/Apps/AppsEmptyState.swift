import SwiftUI

struct AppsEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "app.badge")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No apps added yet")
                .font(.headline)
                .foregroundColor(.white)

            Text("Add your favorite apps in Settings")
                .font(.subheadline)
                .foregroundColor(.gray)

            Button(action: {
                SettingsWindowController.shared.showWindow()
            }) {
                Text("Open Settings")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

#Preview {
    AppsEmptyState()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
}
