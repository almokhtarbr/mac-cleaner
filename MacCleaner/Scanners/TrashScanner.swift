import Foundation

struct TrashScanner: CleanerScanner {
    let category = CleanCategory.trash

    func scan() async -> [CleanableItem] {
        let trashURL = home.appendingPathComponent(".Trash")
        guard fm.fileExists(atPath: trashURL.path) else { return [] }

        let size = FileSize.directoryFast(at: trashURL)
        guard size > 0 else { return [] }

        // Count items in trash
        let count = (try? fm.contentsOfDirectory(atPath: trashURL.path))?.count ?? 0

        return [
            CleanableItem(
                path: trashURL,
                name: "Trash (\(count) items)",
                size: size,
                category: category
            )
        ]
    }
}
