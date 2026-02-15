import Foundation

struct CacheScanner: CleanerScanner {
    let category = CleanCategory.caches

    func scan() async -> [CleanableItem] {
        var items: [CleanableItem] = []

        // ~/Library/Caches/
        let userCaches = home.appendingPathComponent("Library/Caches")
        items.append(contentsOf: scanSubdirectories(of: userCaches, category: category, minSize: 1_000_000))

        // ~/.cache/ (XDG)
        let xdgCache = home.appendingPathComponent(".cache")
        if fm.fileExists(atPath: xdgCache.path) {
            items.append(contentsOf: scanSubdirectories(of: xdgCache, category: category, minSize: 1_000_000))
        }

        return items
    }
}
