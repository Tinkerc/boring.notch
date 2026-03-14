import Foundation
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
    static let claudeTasksOpenWith = Key<ClaudeTasksOpenWith>("claudeTasksOpenWith", default: .surf)
}

/// Enum for directory opening options
enum ClaudeTasksOpenWith: String, Defaults.Serializable, CaseIterable {
    case surf = "Surf"
    case finder = "Finder"
    case vscode = "VS Code"

    func open(path: String) {
        guard let url = URL(string: urlScheme(for: path)) else { return }
        NSWorkspace.shared.open(url)
    }

    private func urlScheme(for path: String) -> String {
        switch self {
        case .surf:
            return "surf://open?path=\(path)"
        case .finder:
            return "file://\(path)"
        case .vscode:
            return "vscode://file/\(path)"
        }
    }
}
