import Foundation

enum DiskAnalyzer {
    static func diskInfo() -> DiskInfo {
        DiskInfo.current()
    }

    /// Quick check: does the path exist and is it a directory?
    static func exists(_ path: String) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }

    static func existsFile(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }
}
