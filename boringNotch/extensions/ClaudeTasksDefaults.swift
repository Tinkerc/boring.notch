import Foundation
import AppKit
import Defaults

/// Extension for Claude Tasks configuration defaults
extension Defaults.Keys {
    /// Enable Claude Tasks monitor
    static let claudeTasksEnabled = Key<Bool>("claudeTasksEnabled", default: true)

    /// Refresh interval in seconds
    static let claudeTasksRefreshInterval = Key<Double>("claudeTasksRefreshInterval", default: 5.0)

    /// Show state change animations
    static let claudeTasksShowAnimation = Key<Bool>("claudeTasksShowAnimation", default: true)

    /// Default app to open directories with
    static let claudeTasksOpenWith = Key<ClaudeTasksOpenWith>("claudeTasksOpenWith", default: .finder)

    /// Favorite apps for Apps Launcher
    static let favoriteApps = Key<[String]>("favoriteApps", default: [])
}

/// Enum for directory opening options
enum ClaudeTasksOpenWith: String, Defaults.Serializable, CaseIterable {
    case finder = "Finder"
    case ghostty = "Ghostty"
    case surf = "Surf"
    case vscode = "VS Code"

    func open(path: String) {
        switch self {
        case .finder:
            openWithFinder(path: path)
        case .ghostty:
            openWithGhostty(path: path)
        case .surf, .vscode:
            let urlString = urlScheme(for: path)
            guard let url = URL(string: urlString) else { return }

            // Check if app is installed
            let appBundleId = self == .surf ? "com.surfapp.surf" : "com.microsoft.VSCode"
            guard NSWorkspace.shared.urlForApplication(withBundleIdentifier: appBundleId) != nil else {
                openWithFinder(path: path)
                return
            }

            NSWorkspace.shared.open(url)
        }
    }

    private func openWithFinder(path: String) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
    }

    private func openWithGhostty(path: String) {
        let ghosttyBundleId = "com.mitchellh.ghostty"
        if NSWorkspace.shared.urlForApplication(withBundleIdentifier: ghosttyBundleId) != nil {
            // Open Ghostty with the directory as argument
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.arguments = ["--working-directory", path]
            NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/Applications/Ghostty.app"),
                                                configuration: configuration)
        } else {
            // Fallback to Finder if Ghostty is not installed
            openWithFinder(path: path)
        }
    }

    private func urlScheme(for path: String) -> String {
        switch self {
        case .surf:
            return "surf://open?path=\(path)"
        case .vscode:
            return "vscode://file/\(path)"
        default:
            return "file://\(path)"
        }
    }
}
