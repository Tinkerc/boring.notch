import SwiftUI

/// Pagination control with dots and navigation arrows
struct PaginationControl: View {
    let currentPage: Int
    let totalPages: Int
    let onPageChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 6) {
            // Page dots
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.white : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
                    .onTapGesture {
                        onPageChange(index)
                    }
            }

            Spacer()

            // Previous button
            if currentPage > 0 {
                Button(action: { onPageChange(currentPage - 1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10))
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Next button
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
