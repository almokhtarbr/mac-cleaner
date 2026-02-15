import AppKit

enum SafeDeleter {
    /// Move items to Trash — never permanent delete.
    /// Returns (successCount, freedBytes, errors)
    static func moveToTrash(items: [CleanableItem]) async -> (deleted: Int, freed: Int64, errors: [String]) {
        var deleted = 0
        var freed: Int64 = 0
        var errors: [String] = []

        for item in items {
            guard !ProtectedPaths.isForbidden(item.path) else {
                errors.append("Skipped protected path: \(item.path.lastPathComponent)")
                continue
            }

            do {
                try await MainActor.run {
                    var resultURL: NSURL?
                    try NSWorkspace.shared.recycle([item.path], completionHandler: nil)
                    // If we get here without throwing, it succeeded
                    _ = resultURL
                }
                deleted += 1
                freed += item.size
                OperationLogger.log(action: "trash", path: item.path.path, size: item.size)
            } catch {
                errors.append("\(item.name): \(error.localizedDescription)")
                OperationLogger.log(action: "error", path: item.path.path, size: 0, note: error.localizedDescription)
            }
        }

        return (deleted, freed, errors)
    }

    /// Safer alternative: use FileManager to trash
    static func trash(items: [CleanableItem]) -> (deleted: Int, freed: Int64, errors: [String]) {
        let fm = FileManager.default
        var deleted = 0
        var freed: Int64 = 0
        var errors: [String] = []

        for item in items {
            guard !ProtectedPaths.isForbidden(item.path) else {
                errors.append("Skipped protected: \(item.name)")
                continue
            }

            do {
                var trashedURL: NSURL?
                try fm.trashItem(at: item.path, resultingItemURL: &trashedURL)
                deleted += 1
                freed += item.size
                OperationLogger.log(action: "trash", path: item.path.path, size: item.size)
            } catch {
                errors.append("\(item.name): \(error.localizedDescription)")
                OperationLogger.log(action: "error", path: item.path.path, size: 0, note: error.localizedDescription)
            }
        }

        return (deleted, freed, errors)
    }
}
