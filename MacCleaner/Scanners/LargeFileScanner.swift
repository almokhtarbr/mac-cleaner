import Foundation

struct LargeFileScanner: CleanerScanner {
    let category = CleanCategory.largeFiles
    let minSize: Int64 = 100_000_000  // 100 MB

    func scan() async -> [CleanableItem] {
        var items: [CleanableItem] = []
        let fm = FileManager.default

        let scanDirs = [
            home.appendingPathComponent("Downloads"),
            home.appendingPathComponent("Desktop"),
            home.appendingPathComponent("Documents"),
        ]

        for dir in scanDirs {
            guard let enumerator = fm.enumerator(
                at: dir,
                includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }

            for case let fileURL as URL in enumerator {
                guard !ProtectedPaths.isForbidden(fileURL) else {
                    enumerator.skipDescendants()
                    continue
                }

                guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                      values.isRegularFile == true else { continue }

                let size = Int64(values.fileSize ?? 0)
                guard size >= minSize else { continue }

                items.append(CleanableItem(
                    path: fileURL,
                    name: fileURL.lastPathComponent,
                    size: size,
                    category: category,
                    isSelected: false  // Never auto-select user files
                ))
            }
        }

        return items.sorted { $0.size > $1.size }
    }
}
