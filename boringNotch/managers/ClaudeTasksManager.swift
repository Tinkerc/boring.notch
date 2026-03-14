import Foundation
import Combine
import AppKit

/// Manager for monitoring Claude Code task state files
@MainActor
class ClaudeTasksManager: ObservableObject {
    static let shared = ClaudeTasksManager()

    // MARK: - Published Properties

    /// All active tasks (waiting + working)
    @Published var tasks: [ClaudeTask] = []

    /// Completed tasks for history display
    @Published var completedTasks: [ClaudeTask] = []

    /// Count of tasks in waiting status
    @Published var waitingCount: Int = 0

    /// Count of tasks in working status
    @Published var workingCount: Int = 0

    // MARK: - Private Properties

    private var timer: Timer?
    private var lastTaskStates: [String: ClaudeTask.TaskStatus] = [:]
    private let stateDir: URL

    // MARK: - Initialization

    init() {
        self.stateDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/workspace/tasks")
    }

    // MARK: - Public Methods

    /// Start monitoring task state files
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { await self?.fetchTasks() }
        }
        Task { await fetchTasks() }
    }

    /// Stop monitoring
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    /// Fetch and parse all task state files
    func fetchTasks() async {
        guard FileManager.default.fileExists(atPath: stateDir.path) else {
            tasks = []
            completedTasks = []
            updateCounts()
            return
        }

        do {
            let files = try FileManager.default.contentsOfDirectory(
                atPath: stateDir.path
            ).filter { $0.hasSuffix(".json") }

            var newTasks: [ClaudeTask] = []
            var doneTasks: [ClaudeTask] = []
            var currentStates: [String: ClaudeTask.TaskStatus] = [:]

            for file in files {
                let filePath = stateDir.appendingPathComponent(file)
                if let data = try? Data(contentsOf: filePath),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let task = ClaudeTask(from: json, filePath: filePath.path) {

                    currentStates[task.id] = task.status

                    if task.status == .done {
                        doneTasks.append(task)
                    } else {
                        newTasks.append(task)
                    }
                }
            }

            // Detect state changes for notifications
            checkForStateChanges(newTasks: newTasks, currentStates: currentStates)

            // Sort: working tasks first, then waiting
            self.tasks = newTasks.sorted {
                $0.status == .working && $1.status != .working
            }
            self.completedTasks = doneTasks

            updateCounts()
            lastTaskStates = currentStates

        } catch {
            print("Error fetching Claude tasks: \(error)")
        }
    }

    // MARK: - Private Methods

    /// Check for task state changes and post notifications
    private func checkForStateChanges(newTasks: [ClaudeTask], currentStates: [String: ClaudeTask.TaskStatus]) {
        for task in newTasks {
            if let oldStatus = lastTaskStates[task.id] {
                if oldStatus == .working && task.status == .done {
                    // Task completed
                    NotificationCenter.default.post(
                        name: .taskCompleted,
                        object: nil,
                        userInfo: ["task": task]
                    )
                } else if oldStatus == .waiting && task.status == .working {
                    // Task started running
                    NotificationCenter.default.post(
                        name: .taskStarted,
                        object: nil,
                        userInfo: ["task": task]
                    )
                }
            }
        }
    }

    /// Update task counts
    private func updateCounts() {
        waitingCount = tasks.filter { $0.status == .waiting }.count
        workingCount = tasks.filter { $0.status == .working }.count
    }

    // MARK: - Computed Properties

    /// Whether there are any tasks
    var hasTasks: Bool {
        !tasks.isEmpty
    }

    /// Whether there are waiting tasks
    var hasWaitingTasks: Bool {
        waitingCount > 0
    }

    /// Whether there are running tasks
    var hasWorkingTasks: Bool {
        workingCount > 0
    }

    /// Group tasks by repository for paginated display
    var tasksGroupedByRepo: [RepoGroup] {
        Dictionary(grouping: tasks, by: { $0.repo })
            .map { RepoGroup(repo: $0.key, tasks: $0.value, cwd: $0.value.first?.cwd ?? "") }
            .sorted { $0.tasks.count > $1.tasks.count }
    }
}

// MARK: - Helper Types

/// Repository group for paginated display
struct RepoGroup {
    let repo: String
    let tasks: [ClaudeTask]
    let cwd: String
}

// MARK: - Notification Names

extension Notification.Name {
    static let taskCompleted = Notification.Name("taskCompleted")
    static let taskStarted = Notification.Name("taskStarted")
}
