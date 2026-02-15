import Foundation

struct LogScanner: CleanerScanner {
    let category = CleanCategory.logs

    func scan() async -> [CleanableItem] {
        var items: [CleanableItem] = []

        // ~/Library/Logs/
        let userLogs = home.appendingPathComponent("Library/Logs")
        items.append(contentsOf: scanSubdirectories(of: userLogs, category: category, minSize: 100_000))

        // Crash reports
        let crashReports = home.appendingPathComponent("Library/Logs/DiagnosticReports")
        if fm.fileExists(atPath: crashReports.path) {
            let size = FileSize.directoryFast(at: crashReports)
            if size > 100_000 {
                items.append(CleanableItem(
                    path: crashReports,
                    name: "Crash Reports",
                    size: size,
                    category: category
                ))
            }
        }

        return items
    }
}
