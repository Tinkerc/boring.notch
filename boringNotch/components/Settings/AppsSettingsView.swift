import SwiftUI

struct AppsSettingsView: View {
    @StateObject private var appsManager = AppsManager.shared
    @State private var searchText = ""

    var filteredApps: [AppsManager.AppEntry] {
        if searchText.isEmpty {
            return appsManager.discoveredApps
        }
        return appsManager.discoveredApps.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left Panel: Available Apps
            VStack(alignment: .leading, spacing: 0) {
                Text("Available Apps")
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                TextField("Search apps...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)

                List(filteredApps) { app in
                    HStack {
                        if let icon = appsManager.getAppIcon(bundleID: app.bundleID) {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 24, height: 24)
                        }

                        Text(app.displayName)
                            .lineLimit(1)

                        Spacer()

                        if !appsManager.isFavorite(app.bundleID) {
                            Button(action: {
                                appsManager.addFavorite(app.bundleID)
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.accentColor)
                                    .font(.system(size: 18))
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 18))
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset)
            }
            .frame(width: 250)

            Divider()
                .frame(height: 300)

            // Right Panel: My Apps
            VStack(alignment: .leading, spacing: 0) {
                Text("My Apps")
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                List(appsManager.getFavoriteEntries()) { app in
                    HStack {
                        if let icon = appsManager.getAppIcon(bundleID: app.bundleID) {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 24, height: 24)
                        }

                        Text(app.displayName)
                            .lineLimit(1)

                        Spacer()

                        Button(action: {
                            appsManager.removeFavorite(app.bundleID)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 18))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset)
            }
            .frame(width: 250)
        }
        .padding()
        .onAppear {
            appsManager.loadFavorites()
        }
    }
}

#Preview {
    AppsSettingsView()
        .frame(width: 520, height: 400)
}
