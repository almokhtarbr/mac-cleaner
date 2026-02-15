import AppKit

enum RunningAppChecker {
    /// Returns bundle identifiers of currently running apps
    static func runningBundleIDs() -> Set<String> {
        Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
    }

    /// Check if an app with this bundle ID is currently running
    static func isRunning(bundleID: String) -> Bool {
        runningBundleIDs().contains(bundleID)
    }

    /// Check if the folder name (often a bundle ID) corresponds to a running app
    static func isRunning(folderName: String) -> Bool {
        let running = runningBundleIDs()
        // Direct match
        if running.contains(folderName) { return true }
        // Partial match (e.g. folder "Google" matches "com.google.Chrome")
        return running.contains(where: { $0.localizedCaseInsensitiveContains(folderName) })
    }
}
