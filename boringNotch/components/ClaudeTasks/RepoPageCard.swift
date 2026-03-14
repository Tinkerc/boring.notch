import SwiftUI
import AppKit

/// Repository group card for paginated expanded view
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
        guard let url = URL(string: "surf://open?path=\(cwd)") else { return }
        NSWorkspace.shared.open(url)
    }
}
