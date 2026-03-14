import SwiftUI
import AppKit

struct AppIconView: View {
    let bundleID: String
    let displayName: String
    let onLaunch: () -> Void

    @State private var icon: NSImage?
    private let appsManager = AppsManager.shared

    var body: some View {
        Button(action: onLaunch) {
            VStack(spacing: 4) {
                if let icon = icon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 42, height: 42)
                        .shadow(radius: 2)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 42, height: 42)
                        .overlay(
                            Image(systemName: "app.badge")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                        )
                }

                Text(displayName)
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(width: 60)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadIcon()
        }
    }

    private func loadIcon() {
        // Check cache first
        if let cachedIcon = appsManager.iconCache[bundleID] {
            icon = cachedIcon
            return
        }

        // Load and cache icon
        if let loadedIcon = appsManager.getAppIcon(bundleID: bundleID) {
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
