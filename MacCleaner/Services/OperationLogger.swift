import Foundation

enum OperationLogger {
    private static let queue = DispatchQueue(label: "com.maccleaner.logger")

    private static let logDir: URL = {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/MacCleaner")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let isoFormatter: ISO8601DateFormatter = {
        ISO8601DateFormatter()
    }()

    private static var logFile: URL {
        let name = dateFormatter.string(from: Date())
        return logDir.appendingPathComponent("\(name).log")
    }

    static func log(action: String, path: String, size: Int64, note: String? = nil) {
        let timestamp = isoFormatter.string(from: Date())
        let sizeStr = FileSize.formatted(size)
        var line = "[\(timestamp)] \(action.uppercased()) \(sizeStr) \(path)"
        if let note { line += " — \(note)" }
        line += "\n"

        queue.async {
            guard let data = line.data(using: .utf8) else { return }
            let file = logFile
            if FileManager.default.fileExists(atPath: file.path) {
                if let handle = try? FileHandle(forWritingTo: file) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                try? data.write(to: file)
            }
        }
    }
}
