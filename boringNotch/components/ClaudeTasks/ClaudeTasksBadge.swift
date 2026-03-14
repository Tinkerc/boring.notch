import SwiftUI

/// Badge display for Claude Tasks in closed notch state
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
