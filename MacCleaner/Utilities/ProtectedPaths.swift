import Foundation

enum ProtectedPaths {
    static let home = FileManager.default.homeDirectoryForCurrentUser

    /// Paths we NEVER touch — iCloud, system, keychains, mail, etc.
    static let forbidden: [String] = [
        home.appendingPathComponent("Library/Mobile Documents").path,      // iCloud Drive
        home.appendingPathComponent("Library/CloudStorage").path,          // iCloud/Dropbox/GDrive/OneDrive
        home.appendingPathComponent("Library/Photos").path,                // iCloud Photos
        home.appendingPathComponent("Library/Mail").path,                  // Email data
        home.appendingPathComponent("Library/Keychains").path,             // Passwords
        home.appendingPathComponent("Library/Cookies").path,               // Auth sessions
        home.appendingPathComponent("Library/Accounts").path,              // System accounts
        home.appendingPathComponent("Library/Biome").path,                 // System intelligence
        home.appendingPathComponent("Library/PersonalizationPortrait").path,
        "/System",
        "/Library/Apple",
        "/usr",
        "/bin",
        "/sbin",
        "/private/var/db",
    ]

    static func isForbidden(_ path: String) -> Bool {
        for protected in forbidden {
            if path.hasPrefix(protected) { return true }
        }
        return false
    }

    static func isForbidden(_ url: URL) -> Bool {
        isForbidden(url.path)
    }
}
