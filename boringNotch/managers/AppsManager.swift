import AppKit
import Defaults
import Foundation

@MainActor
class AppsManager: ObservableObject {
    static let shared = AppsManager()

    @Published var favoriteApps: [String] = []
    @Published var discoveredApps: [AppEntry] = []

    struct AppEntry: Identifiable, Hashable {
        let id = UUID()
        let bundleID: String
        let displayName: String
        let path: String

        func hash(into hasher: inout Hasher) {
            hasher.combine(bundleID)
        }

        static func == (lhs: AppEntry, rhs: AppEntry) -> Bool {
            lhs.bundleID == rhs.bundleID
        }
    }

    private let commonApps = [
        "com.apple.Safari",
        "com.google.Chrome",
        "org.mozilla.firefox",
        "com.microsoft.Edge",
        "company.thebrowser.Browser",
        "com.apple.mail",
        "com.apple.MobileMessages",
        "com.apple.Notes",
        "com.apple.reminders",
        "com.apple.iCal",
        "com.apple.Photos",
        "com.apple.Music",
        "com.spotify.client",
        "com.tinyspeck.slackmacgap",
        "com.hnc.Discord",
        "us.zoom.xos",
        "com.microsoft.teams",
        "com.figma.Desktop",
        "com.microsoft.VSCode",
        "com.jetbrains.intellij",
        "com.runningwithcrayons.Alfred"
    ]

    private init() {
        loadFavorites()
        discoverApps()
    }

    func loadFavorites() {
        favoriteApps = Defaults[.favoriteApps]
    }

    func discoverApps() {
        var apps: [AppEntry] = []

        for bundleID in commonApps {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                if let bundle = Bundle(url: url) {
                    let name = bundle.infoDictionary?["CFBundleName"] as? String
                        ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String
                        ?? (bundleID as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: "")

                    apps.append(AppEntry(bundleID: bundleID, displayName: name, path: url.path))
                }
            }
        }

        discoveredApps = apps
    }

    func addFavorite(_ bundleID: String) {
        if !favoriteApps.contains(bundleID) {
            favoriteApps.append(bundleID)
            Defaults[.favoriteApps] = favoriteApps
        }
    }

    func removeFavorite(_ bundleID: String) {
        favoriteApps.removeAll { $0 == bundleID }
        Defaults[.favoriteApps] = favoriteApps
    }

    func isFavorite(_ bundleID: String) -> Bool {
        favoriteApps.contains(bundleID)
    }

    func getFavoriteEntries() -> [AppEntry] {
        favoriteApps.compactMap { bundleID -> AppEntry? in
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
                return nil
            }

            let name = Bundle(url: url)?.infoDictionary?["CFBundleName"] as? String
                ?? (bundleID as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: "")

            return AppEntry(bundleID: bundleID, displayName: name, path: url.path)
        }
    }

    func launchApp(bundleID: String) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return
        }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }

    func getAppIcon(bundleID: String) -> NSImage? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 64, height: 64)
        return icon
    }
}
