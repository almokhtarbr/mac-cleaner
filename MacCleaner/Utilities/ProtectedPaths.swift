import Foundation

enum ProtectedPaths {
    static let home = FileManager.default.homeDirectoryForCurrentUser

    /// Paths we NEVER touch — iCloud, system, keychains, credentials, app data, etc.
    static let forbidden: [String] = [
        // iCloud & cloud storage
        home.appendingPathComponent("Library/Mobile Documents").path,
        home.appendingPathComponent("Library/CloudStorage").path,

        // User data
        home.appendingPathComponent("Library/Photos").path,
        home.appendingPathComponent("Library/Mail").path,
        home.appendingPathComponent("Library/Messages").path,
        home.appendingPathComponent("Library/Calendars").path,
        home.appendingPathComponent("Library/Contacts").path,
        home.appendingPathComponent("Library/Safari").path,

        // Credentials & security
        home.appendingPathComponent("Library/Keychains").path,
        home.appendingPathComponent("Library/Cookies").path,
        home.appendingPathComponent("Library/Accounts").path,
        home.appendingPathComponent(".ssh").path,
        home.appendingPathComponent(".gnupg").path,
        home.appendingPathComponent(".aws").path,
        home.appendingPathComponent(".kube").path,

        // App settings & data (NOT caches — those are safe)
        home.appendingPathComponent("Library/Preferences").path,
        home.appendingPathComponent("Library/Application Support").path,
        home.appendingPathComponent("Library/Containers").path,
        home.appendingPathComponent("Library/Group Containers").path,

        // System intelligence
        home.appendingPathComponent("Library/Biome").path,
        home.appendingPathComponent("Library/PersonalizationPortrait").path,
        home.appendingPathComponent("Library/Suggestions").path,
        home.appendingPathComponent("Library/CoreData").path,

        // Music / media
        home.appendingPathComponent("Library/Music").path,
        home.appendingPathComponent("Music").path,
        home.appendingPathComponent("Pictures").path,
        home.appendingPathComponent("Movies").path,

        // System directories
        "/System",
        "/Library/Apple",
        "/Library/LaunchDaemons",
        "/Library/LaunchAgents",
        "/usr",
        "/bin",
        "/sbin",
        "/etc",
        "/private/var/db",
    ].map { resolvePath($0) }

    /// Resolve symlinks and normalize path for safe comparison
    private static func resolvePath(_ path: String) -> String {
        (path as NSString).resolvingSymlinksInPath.lowercased()
    }

    /// Check if path is forbidden — case-insensitive, resolves symlinks
    static func isForbidden(_ path: String) -> Bool {
        let resolved = resolvePath(path)
        for protected in forbidden {
            if resolved.hasPrefix(protected) { return true }
        }
        return false
    }

    static func isForbidden(_ url: URL) -> Bool {
        // Resolve symlinks at the URL level first
        let resolved = url.resolvingSymlinksInPath()
        return isForbidden(resolved.path)
    }
}
