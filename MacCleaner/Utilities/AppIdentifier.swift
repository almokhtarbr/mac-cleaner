import AppKit

enum AppIdentifier {
    /// Try to resolve a cache/log folder name to an app name and icon
    static func resolve(folderName: String) -> (name: String, icon: NSImage?) {
        // Common bundle ID patterns
        let bundleID = folderName

        // Try to find the app by bundle identifier
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            let name = FileManager.default.displayName(atPath: appURL.path)
            let icon = NSWorkspace.shared.icon(forFile: appURL.path)
            return (name, icon)
        }

        // Try common mappings
        let knownApps: [String: String] = [
            "com.apple.Safari": "Safari",
            "com.google.Chrome": "Google Chrome",
            "org.mozilla.firefox": "Firefox",
            "com.brave.Browser": "Brave",
            "com.microsoft.VSCode": "VS Code",
            "com.apple.dt.Xcode": "Xcode",
            "com.spotify.client": "Spotify",
            "com.tinyspeck.slackmacgap": "Slack",
            "us.zoom.xos": "Zoom",
            "com.hnc.Discord": "Discord",
            "com.docker.docker": "Docker",
        ]

        if let name = knownApps[bundleID] {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                return (name, NSWorkspace.shared.icon(forFile: appURL.path))
            }
            return (name, nil)
        }

        // Clean up the folder name as a fallback
        let cleaned = folderName
            .replacingOccurrences(of: "com.apple.", with: "")
            .replacingOccurrences(of: "com.", with: "")
            .replacingOccurrences(of: "org.", with: "")
            .replacingOccurrences(of: "io.", with: "")
            .split(separator: ".").last.map(String.init) ?? folderName

        return (cleaned.capitalized, nil)
    }
}
