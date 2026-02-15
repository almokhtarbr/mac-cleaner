import Foundation

struct XcodeScanner: CleanerScanner {
    let category = CleanCategory.xcode

    func scan() async -> [CleanableItem] {
        var items: [CleanableItem] = []

        let paths: [(String, String)] = [
            ("Library/Developer/Xcode/DerivedData", "DerivedData"),
            ("Library/Developer/CoreSimulator/Devices", "Simulators"),
            ("Library/Developer/CoreSimulator/Caches", "Simulator Caches"),
            ("Library/Developer/Xcode/iOS DeviceSupport", "iOS Device Support"),
            ("Library/Developer/Xcode/watchOS DeviceSupport", "watchOS Device Support"),
            ("Library/Developer/Xcode/Archives", "Archives"),
            ("Library/Developer/DeveloperDiskImages", "Developer Disk Images"),
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
                category: category,
                isSelected: name != "Archives"  // Don't auto-select archives
            ))
        }

        return items.sorted { $0.size > $1.size }
    }
}
