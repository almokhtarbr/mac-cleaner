import AppKit

/// Categories where permanent delete is safe — these files regenerate automatically
private let safeToDeletePermanently: Set<CleanCategory> = [
    .caches, .logs, .xcode, .devTools, .browser, .trash
]

enum SafeDeleter {
    /// Permanently remove items that are safe (caches/logs/build artifacts).
    /// User files (large files) still go to Trash.
    static func clean(items: [CleanableItem]) -> (deleted: Int, freed: Int64, errors: [String]) {
        let fm = FileManager.default
        var deleted = 0
        var freed: Int64 = 0
        var errors: [String] = []

        for item in items {
            guard !ProtectedPaths.isForbidden(item.path) else {
                errors.append("Skipped protected: \(item.name)")
                continue
            }

            // Check if running app
            if let appName = item.appName, RunningAppChecker.isRunning(folderName: item.path.lastPathComponent) {
                errors.append("\(appName) is running — skipped")
                continue
            }

            do {
                if item.category == .trash {
                    // Empty trash contents (don't delete the .Trash folder itself)
                    let trashContents = try fm.contentsOfDirectory(at: item.path, includingPropertiesForKeys: nil)
                    for file in trashContents {
                        try fm.removeItem(at: file)
                    }
                    deleted += 1
                    freed += item.size
                    OperationLogger.log(action: "empty-trash", path: item.path.path, size: item.size)
                } else if safeToDeletePermanently.contains(item.category) {
                    // Permanent delete for caches/logs/build artifacts — they regenerate
                    try fm.removeItem(at: item.path)
                    deleted += 1
                    freed += item.size
                    OperationLogger.log(action: "delete", path: item.path.path, size: item.size)
                } else {
                    // Trash for user files (large files, etc.)
                    var trashedURL: NSURL?
                    try fm.trashItem(at: item.path, resultingItemURL: &trashedURL)
                    deleted += 1
                    freed += item.size
                    OperationLogger.log(action: "trash", path: item.path.path, size: item.size)
                }
            } catch {
                errors.append("\(item.name): \(error.localizedDescription)")
                OperationLogger.log(action: "error", path: item.path.path, size: 0, note: error.localizedDescription)
            }
        }

        return (deleted, freed, errors)
    }

    /// Empty the Trash — actually frees disk space
    static func emptyTrash() {
        let script = NSAppleScript(source: """
            tell application "Finder"
                empty the trash
            end tell
        """)
        var error: NSDictionary?
        script?.executeAndReturnError(&error)
        if let error {
            OperationLogger.log(action: "error", path: "Trash", size: 0, note: "Empty trash failed: \(error)")
        } else {
            OperationLogger.log(action: "empty-trash", path: "Trash", size: 0)
        }
    }
}
