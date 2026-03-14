# Claude Tasks Monitor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task.

**Goal:** Integrate Claude Code task monitoring into Boring Notch with badge-style status display and island-style notifications.

**Architecture:** File system watcher monitors `~/.claude/workspace/tasks/*.json`, state managed by `ClaudeTasksManager`, UI rendered with SwiftUI views supporting badge mode (closed notch) and paginated cards (expanded notch).

**Tech Stack:** SwiftUI, Combine, FileSystemMonitor (or polling), existing Boring Notch view hierarchy.

---

## Design Summary

### Visual States

| State | Display | Behavior |
|-------|---------|----------|
| **Closed (no tasks)** | Hidden | No badge shown |
| **Closed (tasks)** | Badge 🟠2 🟡1 | Right-aligned, minimal |
| **State change** | Island overlay | Expand 2s → auto-collapse |
| **Expanded** | Paginated cards | Swipe/click to navigate repos |

### Animation Specs

- **Badge appear:** Slide from right + spring scale (0.3s)
- **Island expand:** Height 32→60, ease-out (0.3s)
- **Complete notify:** Green pulse + checkmark fade (1.5s)
- **Page swipe:** Horizontal slide (0.25s)

### Configuration

```swift
@AppStorage("claudeTasksEnabled") var claudeTasksEnabled = true
@AppStorage("claudeTasksRefreshInterval") var refreshInterval = 5.0
@AppStorage("claudeTasksShowAnimation") var showAnimation = true
@AppStorage("claudeTasksAutoPage") var autoPage = false
@AppStorage("claudeTasksOpenWith") var openWith: OpenWith = .surf
```

---

## Implementation Tasks

### Task 1: Data Model

**Files:**
- Create: `boringNotch/models/ClaudeTask.swift`

**Step 1: Create the data model**

```swift
import Foundation

struct ClaudeTask: Identifiable, Hashable {
    let id: String
    let repo: String
    let task: String
    let status: TaskStatus
    let duration: String
    let cwd: String
    let startTime: TimeInterval

    enum TaskStatus: String, Hashable {
        case waiting, working, done
    }
}

extension ClaudeTask {
    init?(from json: [String: Any], filePath: String) {
        guard
            let repo = json["repo"] as? String,
            let task = json["task"] as? String,
            let statusRaw = json["status"] as? String,
            let startTime = json["start_time"] as? TimeInterval,
            let cwd = json["cwd"] as? String
        else { return nil }

        self.id = filePath.hashValue.description
        self.repo = repo
        self.task = task
        self.status = Self.mapStatus(raw: statusRaw)
        self.startTime = startTime
        self.cwd = cwd

        // Calculate duration
        let diff = Int(Date().timeIntervalSince1970) - Int(startTime)
        if diff < 60 {
            self.duration = "\(diff)s"
        } else if diff < 3600 {
            self.duration = "\(diff / 60)m"
        } else {
            self.duration = "\(diff / 3600)h\((diff % 3600) / 60)m"
        }
    }

    private static func mapStatus(raw: String) -> TaskStatus {
        switch raw {
        case "waiting": return .waiting
        case "working", "active", "agent_running", "running_tool", "waiting_user":
            return .working
        case "done", "interrupted", "error":
            return .done
        default:
            return .waiting
        }
    }
}
```

**Step 2: Commit**

```bash
git add boringNotch/models/ClaudeTask.swift
git commit -m "feat: add ClaudeTask model"
```

---

### Task 2: Manager

**Files:**
- Create: `boringNotch/managers/ClaudeTasksManager.swift`

**Step 1: Create the manager with file polling**

```swift
import Foundation
import Combine
import AppKit

@MainActor
class ClaudeTasksManager: ObservableObject {
    static let shared = ClaudeTasksManager()

    @Published var tasks: [ClaudeTask] = []
    @Published var completedTasks: [ClaudeTask] = []

    @Published var waitingCount: Int = 0
    @Published var workingCount: Int = 0

    private var timer: Timer?
    private var lastTaskStates: [String: TaskStatus] = [:]

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { await self?.fetchTasks() }
        }
        Task { await fetchTasks() }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func fetchTasks() async {
        let stateDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/workspace/tasks")

        guard FileManager.default.fileExists(atPath: stateDir.path) else {
            tasks = []
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

            self.tasks = newTasks.sorted {
                $0.status == .working && $1.status != .working
            }
            self.completedTasks = doneTasks

            updateCounts()
            lastTaskStates = currentStates

        } catch {
            print("Error fetching tasks: \(error)")
        }
    }

    private func checkForStateChanges(newTasks: [ClaudeTask], currentStates: [String: ClaudeTask.TaskStatus]) {
        for task in newTasks {
            if let oldStatus = lastTaskStates[task.id] {
                if oldStatus == .working && task.status == .done {
                    // Task completed - trigger notification
                    NotificationCenter.default.post(
                        name: .taskCompleted,
                        object: nil,
                        userInfo: ["task": task]
                    )
                } else if oldStatus == .waiting && task.status == .working {
                    // Task started
                    NotificationCenter.default.post(
                        name: .taskStarted,
                        object: nil,
                        userInfo: ["task": task]
                    )
                }
            }
        }
    }

    private func updateCounts() {
        waitingCount = tasks.filter { $0.status == .waiting }.count
        workingCount = tasks.filter { $0.status == .working }.count
    }

    var hasTasks: Bool {
        !tasks.isEmpty
    }

    var hasWaitingTasks: Bool {
        waitingCount > 0
    }

    var hasWorkingTasks: Bool {
        workingCount > 0
    }
}

extension Notification.Name {
    static let taskCompleted = Notification.Name("taskCompleted")
    static let taskStarted = Notification.Name("taskStarted")
}
```

**Step 2: Commit**

```bash
git add boringNotch/managers/ClaudeTasksManager.swift
git commit -m "feat: add ClaudeTasksManager with file polling"
```

---

### Task 3: Badge View

**Files:**
- Create: `boringNotch/components/ClaudeTasks/ClaudeTasksBadge.swift`

**Step 1: Create the badge component**

```swift
import SwiftUI

struct ClaudeTasksBadge: View {
    @ObservedObject var manager = ClaudeTasksManager.shared

    var body: some View {
        Group {
            if manager.hasWaitingTasks {
                badgeContent(icon: "🟠", count: manager.waitingCount)
                    .transition(.slide.combined(with: .scale))
            } else if manager.hasWorkingTasks {
                badgeContent(icon: "🟡", count: manager.workingCount)
                    .transition(.slide.combined(with: .scale))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: manager.tasks)
    }

    @ViewBuilder
    private func badgeContent(icon: String, count: Int) -> some View {
        HStack(spacing: 4) {
            Text(icon)
                .font(.system(size: 12))
            Text("\(count)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.6))
                .blur(radius: 8)
        )
    }
}
```

**Step 2: Commit**

```bash
git add boringNotch/components/ClaudeTasks/ClaudeTasksBadge.swift
git commit -m "feat: add ClaudeTasksBadge component"
```

---

### Task 4: Island Overlay

**Files:**
- Create: `boringNotch/components/ClaudeTasks/ClaudeTasksOverlay.swift`

**Step 1: Create the island notification overlay**

```swift
import SwiftUI

struct ClaudeTasksOverlay: View {
    @ObservedObject var manager = ClaudeTasksManager.shared
    @State private var isExpanded = false
    @State private var currentTask: ClaudeTask?

    var body: some View {
        Group {
            if isExpanded, let task = currentTask {
                expandedView(for: task)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .taskCompleted)) { notification in
            if let task = notification.userInfo?["task"] as? ClaudeTask {
                showCompletion(task: task)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .taskStarted)) { notification in
            if let task = notification.userInfo?["task"] as? ClaudeTask {
                showStart(task: task)
            }
        }
    }

    private func expandedView(for task: ClaudeTask) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: task.status == .done ? "checkmark.circle.fill" : "play.circle.fill")
                    .foregroundColor(task.status == .done ? .green : .yellow)
                Text(task.status == .done ? "Task Complete" : "Running")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                Text(task.duration)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Text(task.task)
                .font(.caption)
                .lineLimit(2)

            Text(task.repo)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.85))
        )
        .foregroundColor(.white)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    isExpanded = false
                }
            }
        }
    }

    private func showCompletion(task: ClaudeTask) {
        currentTask = task
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isExpanded = true
        }
    }

    private func showStart(task: ClaudeTask) {
        currentTask = task
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isExpanded = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                isExpanded = false
            }
        }
    }
}
```

**Step 2: Commit**

```bash
git add boringNotch/components/ClaudeTasks/ClaudeTasksOverlay.swift
git commit -m "feat: add ClaudeTasksOverlay for island notifications"
```

---

### Task 5: Paginated Cards

**Files:**
- Create: `boringNotch/components/ClaudeTasks/ClaudeTasksExpandedView.swift`
- Create: `boringNotch/components/ClaudeTasks/RepoPageCard.swift`
- Create: `boringNotch/components/ClaudeTasks/TaskRow.swift`
- Create: `boringNotch/components/ClaudeTasks/PaginationControl.swift`

**Step 1: Create TaskRow**

```swift
import SwiftUI

struct TaskRow: View {
    let task: ClaudeTask

    var body: some View {
        HStack(spacing: 8) {
            Text(task.status == .waiting ? "🟠" : "🟡")
                .font(.system(size: 10))

            Text(task.task)
                .font(.caption)
                .lineLimit(1)
                .truncationStrategy(.tail)

            Spacer()

            Text(task.duration)
                .font(.caption2)
                .foregroundColor(.gray)

            Image(systemName: "arrow.up.right.square")
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}
```

**Step 2: Create RepoPageCard**

```swift
import SwiftUI

struct RepoPageCard: View {
    let repo: String
    let tasks: [ClaudeTask]
    let cwd: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "folder.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
                Text(repo)
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: openInSurf) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 10))
                }
                .buttonStyle(PlainButtonStyle())
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                ForEach(tasks) { task in
                    TaskRow(task: task)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func openInSurf() {
        if let url = URL(string: "surf://open?path=\(cwd)") {
            NSWorkspace.shared.open(url)
        }
    }
}
```

**Step 3: Create PaginationControl**

```swift
import SwiftUI

struct PaginationControl: View {
    let currentPage: Int
    let totalPages: Int
    let onPageChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.white : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
                    .onTapGesture {
                        onPageChange(index)
                    }
            }

            Spacer()

            if currentPage > 0 {
                Button(action: { onPageChange(currentPage - 1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10))
                }
                .buttonStyle(PlainButtonStyle())
            }

            if currentPage < totalPages - 1 {
                Button(action: { onPageChange(currentPage + 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}
```

**Step 4: Create ClaudeTasksExpandedView**

```swift
import SwiftUI

struct ClaudeTasksExpandedView: View {
    @ObservedObject var manager = ClaudeTasksManager.shared
    @State private var currentPage = 0

    private var groupedTasks: [[ClaudeTask]] {
        Dictionary(grouping: manager.tasks, by: { $0.repo })
            .map { RepoGroup(repo: $0.key, tasks: $0.value, cwd: $0.value.first?.cwd ?? "") }
            .sorted { $0.tasks.count > $1.tasks.count }
            .map { $0.tasks }
    }

    private var repoGroups: [RepoGroup] {
        Dictionary(grouping: manager.tasks, by: { $0.repo })
            .map { RepoGroup(repo: $0.key, tasks: $0.value, cwd: $0.value.first?.cwd ?? "") }
            .sorted { $0.tasks.count > $1.tasks.count }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Claude Tasks")
                    .font(.caption)
                    .fontWeight(.semibold)

                Spacer()

                PaginationControl(
                    currentPage: currentPage,
                    totalPages: max(groupedTasks.count, 1)
                ) { page in
                    withAnimation {
                        currentPage = page
                    }
                }
            }

            // Cards
            TabView(selection: $currentPage) {
                ForEach(Array(repoGroups.enumerated()), id: \.element.repo) { index, group in
                    RepoPageCard(repo: group.repo, tasks: group.tasks, cwd: group.cwd)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Footer stats
            HStack(spacing: 12) {
                Label("\(manager.waitingCount)", systemImage: "circlebadge.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)

                Label("\(manager.workingCount)", systemImage: "circlebadge.fill")
                    .font(.caption2)
                    .foregroundColor(.yellow)

                Divider()
                    .frame(height: 12)

                Text("📜 \(manager.tasks.count + manager.completedTasks.count) tasks")
                    .font(.caption2)
                    .foregroundColor(.gray)

                Spacer()

                Button(action: { Task { await manager.fetchTasks() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(10)
    }
}

private struct RepoGroup {
    let repo: String
    let tasks: [ClaudeTask]
    let cwd: String
}
```

**Step 5: Commit**

```bash
git add boringNotch/components/ClaudeTasks/*.swift
git commit -m "feat: add paginated card views for Claude Tasks"
```

---

### Task 6: Integrate into NotchHomeView

**Files:**
- Modify: `boringNotch/components/Notch/NotchHomeView.swift`

**Step 1: Add ClaudeTasksBadge to the header**

Find the `MusicPlayerView` section and add the badge overlay.

**Step 2: Commit**

```bash
git add boringNotch/components/Notch/NotchHomeView.swift
git commit -m "feat: integrate ClaudeTasksBadge into NotchHomeView"
```

---

### Task 7: Add Configuration UI

**Files:**
- Modify: `boringNotch/components/Settings/SettingsView.swift`

**Step 1: Add Claude Tasks section to settings**

```swift
Section("Claude Tasks") {
    Toggle("Enable Claude Tasks Monitor", isOn: $claudeTasksEnabled)
    Stepper("Refresh Interval: \(Int(refreshInterval))s",
            value: $refreshInterval, in: 2...30, step: 1)
    Toggle("Show Animations", isOn: $showAnimation)
    Picker("Open With", selection: $openWith) {
        Text("Surf").tag(OpenWith.surf)
        Text("Finder").tag(OpenWith.finder)
        Text("VS Code").tag(OpenWith.vscode)
    }
}
```

**Step 2: Commit**

```bash
git add boringNotch/components/Settings/SettingsView.swift
git commit -m "feat: add Claude Tasks configuration to Settings"
```

---

### Task 8: Initialize Manager in App

**Files:**
- Modify: `boringNotch/boringNotchApp.swift`

**Step 1: Start monitoring on app launch**

```swift
@main
struct boringNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    ClaudeTasksManager.shared.startMonitoring()
                }
        }
        .commands { }
    }
}
```

**Step 2: Commit**

```bash
git add boringNotch/boringNotchApp.swift
git commit -m "feat: start ClaudeTasksManager on app launch"
```

---

### Task 9: Testing

**Files:**
- Create: `boringNotchTests/ClaudeTasksManagerTests.swift`

**Step 1: Write tests for task parsing and state detection**

```swift
import XCTest
@testable import boringNotch

@MainActor
final class ClaudeTasksManagerTests: XCTestCase {
    func testTaskModelParsing() async {
        let sampleJSON: [String: Any] = [
            "repo": "test-repo",
            "task": "Test task description",
            "status": "working",
            "start_time": Date().timeIntervalSince1970 - 120,
            "cwd": "/tmp/test"
        ]

        let task = ClaudeTask(from: sampleJSON, filePath: "/tmp/test.json")

        XCTAssertNotNil(task)
        XCTAssertEqual(task?.repo, "test-repo")
        XCTAssertEqual(task?.status, .working)
        XCTAssertEqual(task?.duration, "2m")
    }

    func testStatusMapping() {
        XCTAssertEqual(ClaudeTask.mapStatus(raw: "waiting"), .waiting)
        XCTAssertEqual(ClaudeTask.mapStatus(raw: "working"), .working)
        XCTAssertEqual(ClaudeTask.mapStatus(raw: "active"), .working)
        XCTAssertEqual(ClaudeTask.mapStatus(raw: "done"), .done)
        XCTAssertEqual(ClaudeTask.mapStatus(raw: "error"), .done)
    }
}
```

**Step 2: Run tests**

```bash
xcodebuild test -scheme boringNotch -destination 'platform=macOS'
```

**Step 3: Commit**

```bash
git add boringNotchTests/ClaudeTasksManagerTests.swift
git commit -m "test: add ClaudeTasksManager tests"
```

---

## Verification Checklist

- [ ] Badge displays correctly in closed notch state
- [ ] Island overlay expands on state changes
- [ ] Paginated cards work with multiple repos
- [ ] Settings persistence works
- [ ] File polling updates every 5 seconds
- [ ] Tests pass

---

## Open With Options

Add to helpers:

```swift
enum OpenWith: String, CaseIterable {
    case surf = "Surf"
    case finder = "Finder"
    case vscode = "VS Code"

    func open(path: String) {
        switch self {
        case .surf:
            if let url = URL(string: "surf://open?path=\(path)") {
                NSWorkspace.shared.open(url)
            }
        case .finder:
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
        case .vscode:
            if let url = URL(string: "vscode://file/\(path)") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
```
