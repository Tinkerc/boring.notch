import Foundation

/// Represents a Claude Code agent task loaded from JSON state files
struct ClaudeTask: Identifiable, Hashable {
    /// Unique identifier (hash of file path)
    let id: String
    /// Repository/project name
    let repo: String
    /// Task description
    let task: String
    /// Current task status
    let status: TaskStatus
    /// Formatted duration string (e.g., "2m", "1h 5m")
    let duration: String
    /// Working directory
    let cwd: String
    /// Unix timestamp when task started
    let startTime: TimeInterval

    /// Task status enum with state mapping
    enum TaskStatus: String, Hashable {
        case waiting
        case working
        case done
    }
}

// MARK: - Initialization

extension ClaudeTask {
    /// Initialize from JSON state file
    /// - Parameters:
    ///   - json: JSON dictionary from state file
    ///   - filePath: Path to the state file (used for ID)
    init?(from json: [String: Any], filePath: String) {
        guard
            let repo = json["repo"] as? String,
            let task = json["task"] as? String,
            let statusRaw = json["status"] as? String,
            let startTime = json["start_time"] as? TimeInterval,
            let cwd = json["cwd"] as? String
        else {
            return nil
        }

        self.id = filePath.hashValue.description
        self.repo = repo
        self.task = task
        self.status = Self.mapStatus(raw: statusRaw)
        self.startTime = startTime
        self.cwd = cwd

        // Calculate duration
        let diff = Int(Date().timeIntervalSince1970) - Int(startTime)
        self.duration = Self.formatDuration(diff)
    }

    /// Map raw status strings to TaskStatus enum
    private static func mapStatus(raw: String) -> TaskStatus {
        switch raw {
        case "waiting":
            return .waiting
        case "working", "active", "agent_running", "running_tool", "waiting_user":
            return .working
        case "done", "interrupted", "error":
            return .done
        default:
            return .waiting
        }
    }

    /// Format seconds into human-readable duration
    private static func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else if seconds < 3600 {
            return "\(seconds / 60)m"
        } else {
            let hours = seconds / 3600
            let minutes = (seconds % 3600) / 60
            return "\(hours)h\(minutes)m"
        }
    }
}
