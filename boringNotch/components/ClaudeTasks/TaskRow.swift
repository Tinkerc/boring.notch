import SwiftUI

/// Single task row display in expanded view
struct TaskRow: View {
    let task: ClaudeTask

    var body: some View {
        HStack(spacing: 8) {
            Text(task.status == .waiting ? "🟠" : "🟡")
                .font(.system(size: 10))

            Text(task.task)
                .font(.caption)
                .lineLimit(1)

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
