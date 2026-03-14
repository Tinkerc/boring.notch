import SwiftUI

/// Island-style overlay notification for task state changes
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

    @ViewBuilder
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
