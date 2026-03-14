import SwiftUI

/// Expanded view with paginated repository cards
struct ClaudeTasksExpandedView: View {
    @ObservedObject var manager = ClaudeTasksManager.shared
    @State private var currentPage = 0

    private var repoGroups: [RepoGroup] {
        manager.tasksGroupedByRepo
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header with pagination
            HStack {
                Text("Claude Tasks")
                    .font(.caption)
                    .fontWeight(.semibold)

                Spacer()

                PaginationControl(
                    currentPage: currentPage,
                    totalPages: max(repoGroups.count, 1)
                ) { page in
                    withAnimation {
                        currentPage = page
                    }
                }
            }

            // Paginated cards
            Group {
                if repoGroups.isEmpty {
                    Text("No tasks")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    let group = repoGroups[currentPage % repoGroups.count]
                    RepoPageCard(repo: group.repo, tasks: group.tasks, cwd: group.cwd)
                }
            }
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
    }
}
