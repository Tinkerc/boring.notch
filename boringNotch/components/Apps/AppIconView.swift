import SwiftUI
import AppKit

struct AppIconView: View {
    let bundleID: String
    let displayName: String
    let onLaunch: () -> Void

    @State private var icon: NSImage?

    var body: some View {
        Button(action: onLaunch) {
            VStack(spacing: 8) {
                if let icon = icon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 64, height: 64)
                        .shadow(radius: 2)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: "app.badge")
                                .foregroundColor(.gray)
                                .font(.system(size: 24))
                        )
                }

                Text(displayName)
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(width: 80)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadIcon()
        }
    }

    private func loadIcon() {
        if let loadedIcon = AppsManager.shared.getAppIcon(bundleID: bundleID) {
            icon = loadedIcon
        }
    }
}

#Preview {
    AppIconView(
        bundleID: "com.apple.Safari",
        displayName: "Safari",
        onLaunch: {}
    )
    .frame(width: 100, height: 100)
    .background(Color.black)
}
