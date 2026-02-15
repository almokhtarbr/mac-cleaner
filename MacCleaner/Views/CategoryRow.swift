import SwiftUI

struct CategoryRow: View {
    @Binding var result: ScanResult
    let vm: CleanerViewModel
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Category header
            HStack(spacing: 12) {
                Image(systemName: result.category.icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(result.category.rawValue)
                            .font(.body)
                            .fontWeight(.medium)
                        Text(result.category == .largeFiles ? "Trash" : "Delete")
                            .font(.system(size: 9))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(result.category == .largeFiles ? Color.orange.opacity(0.15) : Color.red.opacity(0.1))
                            .foregroundColor(result.category == .largeFiles ? .orange : .red)
                            .cornerRadius(3)
                    }
                    Text(result.category.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(FileSize.formatted(result.totalSize))
                    .font(.callout)
                    .fontWeight(.medium)
                    .monospacedDigit()

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }

            // Expanded items
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(result.items.indices, id: \.self) { idx in
                        ItemRow(item: $result.items[idx])
                    }
                }
                .padding(.leading, 60)
                .padding(.trailing, 20)
                .padding(.bottom, 8)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }
}

struct ItemRow: View {
    @Binding var item: CleanableItem

    var body: some View {
        HStack(spacing: 10) {
            Toggle("", isOn: $item.isSelected)
                .toggleStyle(.checkbox)
                .labelsHidden()

            if let icon = item.appIcon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 18, height: 18)
            }

            Text(item.name)
                .font(.callout)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Text(FileSize.formatted(item.size))
                .font(.callout)
                .monospacedDigit()
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 3)
    }
}
