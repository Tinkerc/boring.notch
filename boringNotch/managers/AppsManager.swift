import AppKit
import Defaults
import Foundation

@MainActor
class AppsManager: ObservableObject {
    static let shared = AppsManager()

    @Published var favoriteApps: [String] = []
    @Published var discoveredApps: [AppEntry] = []
    @Published var iconCache: [String: NSImage] = [:]

    private var hasDiscoveredApps = false

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

    // Fallback common apps for quick access (used if /Applications scan fails)
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
        // Only discover apps once per session
        guard !hasDiscoveredApps else { return }

        Task.detached { [weak self] in
            guard let self = self else { return }

            var apps: [AppEntry] = []
            let appDirectories = [
                FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask).first?.path,
                FileManager.default.urls(for: .applicationDirectory, in: .userDomainMask).first?.path,
                "/Applications/Setapp"
            ].compactMap { $0 }

            var foundBundleIDs: Set<String> = []

            for dirPath in appDirectories {
                guard let urls = FileManager.default.enumerator(at: URL(fileURLWithPath: dirPath), includingPropertiesForKeys: nil)?.compactMap({ $0 as? URL }) else {
                    continue
                }

                for url in urls where url.pathExtension == "app" {
                    guard let bundle = Bundle(url: url),
                          let bundleID = bundle.bundleIdentifier,
                          !foundBundleIDs.contains(bundleID) else {
                        continue
                    }

                    let name = bundle.infoDictionary?["CFBundleName"] as? String
                        ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String
                        ?? url.deletingPathExtension().lastPathComponent

                    foundBundleIDs.insert(bundleID)
                    apps.append(AppEntry(bundleID: bundleID, displayName: name, path: url.path))
                }
            }

            // Fallback to common apps if no apps found
            if apps.isEmpty {
                for bundleID in self.commonApps {
                    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                        if let bundle = Bundle(url: url) {
                            let name = bundle.infoDictionary?["CFBundleName"] as? String
                                ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String
                                ?? (bundleID as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: "")

                            apps.append(AppEntry(bundleID: bundleID, displayName: name, path: url.path))
                        }
                    }
                }
            }

            let sortedApps = apps.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }

            await MainActor.run {
                self.discoveredApps = sortedApps
                self.hasDiscoveredApps = true
            }
        }
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
        // Return cached icon if available
        if let cachedIcon = iconCache[bundleID] {
            return cachedIcon
        }

        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 64, height: 64)

        // Cache the icon
        iconCache[bundleID] = icon

        return icon
    }
}
