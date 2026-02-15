import Foundation

/// Scans project directories for dependency folders that can be regenerated
/// (node_modules, .venv, vendor, Pods, .build, target, etc.)
struct ProjectLeftoversScanner: CleanerScanner {
    let category = CleanCategory.projectLeftovers

    /// Folder names that are safe to delete — they regenerate with a single command
    private let targetFolders: [(name: String, label: String, regenerate: String)] = [
        ("node_modules",   "node_modules",    "npm install"),
        (".venv",          "Python venv",      "python -m venv"),
        ("venv",           "Python venv",      "python -m venv"),
        ("__pycache__",    "Python cache",     "runs automatically"),
        ("vendor",         "vendor",           "bundle install / composer install"),
        ("Pods",           "CocoaPods",        "pod install"),
        (".build",         "Swift build",      "swift build"),
        ("target",         "Rust/Maven build", "cargo build / mvn compile"),
        ("build",          "Build output",     "rebuild project"),
        ("dist",           "Dist output",      "rebuild project"),
        (".next",          "Next.js cache",    "next build"),
        (".nuxt",          "Nuxt cache",       "nuxt build"),
        (".turbo",         "Turbo cache",      "turbo run build"),
    ]

    /// Directories to scan for projects
    private var scanRoots: [URL] {
        [
            home.appendingPathComponent("Developer"),
            home.appendingPathComponent("Developer.nosync"),
            home.appendingPathComponent("Projects"),
            home.appendingPathComponent("Code"),
            home.appendingPathComponent("repos"),
            home.appendingPathComponent("src"),
            home.appendingPathComponent("Sites"),
            home.appendingPathComponent("Documents"),
        ].filter { fm.fileExists(atPath: $0.path) }
    }

    func scan() async -> [CleanableItem] {
        var items: [CleanableItem] = []
        let targetNames = Set(targetFolders.map(\.name))

        for root in scanRoots {
            scanDirectory(root, targetNames: targetNames, items: &items, depth: 0)
        }

        return items.sorted { $0.size > $1.size }
    }

    private func scanDirectory(_ dir: URL, targetNames: Set<String>, items: inout [CleanableItem], depth: Int) {
        // Don't go too deep
        guard depth < 5 else { return }
        guard !ProtectedPaths.isForbidden(dir) else { return }

        guard let contents = try? fm.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        for url in contents {
            guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey]),
                  values.isDirectory == true else { continue }

            let name = url.lastPathComponent

            // Skip common non-project directories
            if name.hasPrefix(".") && !targetNames.contains(name) { continue }
            if name == "Library" || name == "Applications" { continue }

            if targetNames.contains(name) {
                let size = FileSize.directoryFast(at: url)
                guard size > 5_000_000 else { continue } // > 5MB

                let info = targetFolders.first(where: { $0.name == name })
                let projectName = url.deletingLastPathComponent().lastPathComponent
                let label = "\(projectName)/\(info?.label ?? name)"

                items.append(CleanableItem(
                    path: url,
                    name: label,
                    size: size,
                    category: category,
                    isSelected: size > 50_000_000  // Auto-select if > 50MB
                ))
            } else {
                // Recurse into subdirectories
                scanDirectory(url, targetNames: targetNames, items: &items, depth: depth + 1)
            }
        }
    }
}
