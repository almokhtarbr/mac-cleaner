import AppKit

/// Categories where permanent delete is safe — these files regenerate automatically
private let safeToDeletePermanently: Set<CleanCategory> = [
    .caches, .logs, .xcode, .devTools, .browser, .trash, .projectLeftovers
]

enum SafeDeleter {
    /// Permanently remove items that are safe (caches/logs/build artifacts).
    /// Docker items cleaned via CLI. User files (large files) go to Trash.
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

            // Check if running app (skip for docker/project leftovers)
            if item.category != .docker && item.category != .projectLeftovers {
                if let appName = item.appName, RunningAppChecker.isRunning(folderName: item.path.lastPathComponent) {
                    errors.append("\(appName) is running — skipped")
                    continue
                }
            }

            do {
                if item.category == .docker {
                    // Docker cleanup via CLI
                    let result = cleanDocker(item: item)
                    if result {
                        deleted += 1
                        freed += item.size
                        OperationLogger.log(action: "docker-clean", path: item.name, size: item.size)
                    } else {
                        errors.append("\(item.name): docker command failed")
                    }
                } else if item.category == .trash {
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

    // MARK: - Docker cleanup

    private static func cleanDocker(item: CleanableItem) -> Bool {
        let name = item.name.lowercased()
        var args: [String] = []

        if name.contains("dangling") {
            args = ["image", "prune", "-f"]
        } else if name.contains("stopped") || name.contains("container") {
            args = ["container", "prune", "-f"]
        } else if name.contains("build cache") {
            args = ["builder", "prune", "-f"]
        } else if name.contains("desktop data") {
            // Don't nuke Docker Desktop data via CLI — too dangerous
            return false
        } else {
            return false
        }

        return runDockerCommand(args)
    }

    private static func runDockerCommand(_ args: [String]) -> Bool {
        let process = Process()
        let dockerPath: String
        if FileManager.default.fileExists(atPath: "/usr/local/bin/docker") {
            dockerPath = "/usr/local/bin/docker"
        } else if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/docker") {
            dockerPath = "/opt/homebrew/bin/docker"
        } else {
            return false
        }

        process.executableURL = URL(fileURLWithPath: dockerPath)
        process.arguments = args
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    /// Empty the Trash
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
