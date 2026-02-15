import Foundation

struct BrowserCacheScanner: CleanerScanner {
    let category = CleanCategory.browser

    func scan() async -> [CleanableItem] {
        var items: [CleanableItem] = []

        let browsers: [(String, String, String)] = [
            ("Library/Caches/Google/Chrome", "Google Chrome", "com.google.Chrome"),
            ("Library/Caches/Firefox/Profiles", "Firefox", "org.mozilla.firefox"),
            ("Library/Caches/com.apple.Safari", "Safari", "com.apple.Safari"),
            ("Library/Caches/BraveSoftware/Brave-Browser", "Brave", "com.brave.Browser"),
            ("Library/Caches/com.microsoft.edgemac", "Microsoft Edge", "com.microsoft.edgemac"),
            ("Library/Caches/com.operasoftware.Opera", "Opera", "com.operasoftware.Opera"),
        ]

        for (relativePath, name, bundleID) in browsers {
            let url = home.appendingPathComponent(relativePath)
            guard fm.fileExists(atPath: url.path) else { continue }
            let size = FileSize.directoryFast(at: url)
            guard size > 500_000 else { continue }

            let isRunning = RunningAppChecker.isRunning(bundleID: bundleID)
            let icon = AppIdentifier.resolve(folderName: bundleID).icon

            items.append(CleanableItem(
                path: url,
                name: name,
                size: size,
                category: category,
                appName: name,
                appIcon: icon,
                isSelected: !isRunning
            ))
        }

        return items.sorted { $0.size > $1.size }
    }
}
