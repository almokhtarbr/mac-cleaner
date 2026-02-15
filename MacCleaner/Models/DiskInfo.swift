import Foundation

struct DiskInfo {
    let totalSpace: Int64
    let usedSpace: Int64
    let freeSpace: Int64

    var usedPercentage: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(usedSpace) / Double(totalSpace)
    }

    static func current() -> DiskInfo {
        do {
            let values = try URL(fileURLWithPath: "/")
                .resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey])
            let total = Int64(values.volumeTotalCapacity ?? 0)
            let free = values.volumeAvailableCapacityForImportantUsage ?? 0
            return DiskInfo(totalSpace: total, usedSpace: total - free, freeSpace: free)
        } catch {
            return DiskInfo(totalSpace: 0, usedSpace: 0, freeSpace: 0)
        }
    }
}
