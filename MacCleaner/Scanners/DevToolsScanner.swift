import Foundation

struct DevToolsScanner: CleanerScanner {
    let category = CleanCategory.devTools

    func scan() async -> [CleanableItem] {
        var items: [CleanableItem] = []

        let paths: [(String, String)] = [
            ("Library/Caches/Homebrew", "Homebrew"),
            (".npm", "npm"),
            ("Library/Caches/Yarn", "Yarn"),
            (".pnpm-store", "pnpm"),
            (".cocoapods/repos", "CocoaPods"),
            (".cargo/registry", "Cargo"),
            (".gem", "RubyGems"),
            (".gradle/caches", "Gradle"),
            (".m2/repository", "Maven"),
            ("Library/Caches/pip", "pip"),
            (".cache/go-build", "Go Build"),
            (".nuget/packages", "NuGet"),
        ]

        for (relativePath, name) in paths {
            let url = home.appendingPathComponent(relativePath)
            guard fm.fileExists(atPath: url.path) else { continue }
            let size = FileSize.directoryFast(at: url)
            guard size > 1_000_000 else { continue }

            items.append(CleanableItem(
                path: url,
                name: name,
                size: size,
                category: category
            ))
        }

        return items.sorted { $0.size > $1.size }
    }
}
