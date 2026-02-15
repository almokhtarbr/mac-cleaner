import Foundation

enum OperationLogger {
    private static let logDir: URL = {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/MacCleaner")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private static var logFile: URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let name = formatter.string(from: Date())
        return logDir.appendingPathComponent("\(name).log")
    }

    static func log(action: String, path: String, size: Int64, note: String? = nil) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let sizeStr = FileSize.formatted(size)
        var line = "[\(timestamp)] \(action.uppercased()) \(sizeStr) \(path)"
        if let note { line += " — \(note)" }
        line += "\n"

        if let data = line.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFile.path) {
                if let handle = try? FileHandle(forWritingTo: logFile) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                try? data.write(to: logFile)
            }
        }
    }
}
