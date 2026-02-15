import Foundation

protocol CleanerScanner {
    var category: CleanCategory { get }
    func scan() async -> [CleanableItem]
}

/// Shared helpers for all scanners
extension CleanerScanner {
    var home: URL { FileManager.default.homeDirectoryForCurrentUser }
    var fm: FileManager { .default }

    /// Scan subdirectories of a folder, returning each subfolder as a CleanableItem
    func scanSubdirectories(of parent: URL, category: CleanCategory, minSize: Int64 = 0) -> [CleanableItem] {
        guard fm.fileExists(atPath: parent.path) else { return [] }
        guard let contents = try? fm.contentsOfDirectory(at: parent, includingPropertiesForKeys: nil) else { return [] }

        var items: [CleanableItem] = []
        for url in contents {
            guard !ProtectedPaths.isForbidden(url) else { continue }
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { continue }

            let size = FileSize.directoryFast(at: url)
            guard size >= minSize else { continue }

            let folderName = url.lastPathComponent
            let resolved = AppIdentifier.resolve(folderName: folderName)
            let isRunning = RunningAppChecker.isRunning(folderName: folderName)

            items.append(CleanableItem(
                path: url,
                name: resolved.name,
                size: size,
                category: category,
                appName: resolved.name,
                appIcon: resolved.icon,
                isSelected: !isRunning  // Don't auto-select running apps
            ))
        }

        return items.sorted { $0.size > $1.size }
    }
}
