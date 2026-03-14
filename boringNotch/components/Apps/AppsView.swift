import SwiftUI

struct AppsView: View {
    @StateObject private var appsManager = AppsManager.shared
    private let columns = [
        GridItem(.fixed(80), spacing: 12),
        GridItem(.fixed(80), spacing: 12),
        GridItem(.fixed(80), spacing: 12),
        GridItem(.fixed(80), spacing: 12)
    ]

    var body: some View {
        Group {
            if appsManager.favoriteApps.isEmpty {
                AppsEmptyState()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(appsManager.getFavoriteEntries()) { entry in
                            AppIconView(
                                bundleID: entry.bundleID,
                                displayName: entry.displayName,
                                onLaunch: {
                                    appsManager.launchApp(bundleID: entry.bundleID)
                                }
                            )
                        }
                    }
                    .padding(16)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AppsView()
        .frame(width: 400, height: 300)
        .background(Color.black)
}
