import Foundation

enum CleanStats {
    private static let defaults = UserDefaults.standard

    private enum Key {
        static let totalCleanedHigh = "stats.totalCleaned.high"
        static let totalCleanedLow = "stats.totalCleaned.low"
        static let totalItems = "stats.totalItems"
        static let totalScans = "stats.totalScans"
        static let lastCleanDate = "stats.lastCleanDate"
    }

    /// Total bytes cleaned — stored as two Int32s to avoid Int64 truncation in UserDefaults
    static var totalCleaned: Int64 {
        let high = Int64(defaults.integer(forKey: Key.totalCleanedHigh))
        let low = Int64(defaults.integer(forKey: Key.totalCleanedLow))
        return (high << 32) | (low & 0xFFFFFFFF)
    }

    static var totalItems: Int {
        defaults.integer(forKey: Key.totalItems)
    }

    static var totalScans: Int {
        defaults.integer(forKey: Key.totalScans)
    }

    static var lastCleanDate: Date? {
        defaults.object(forKey: Key.lastCleanDate) as? Date
    }

    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return f
    }()

    static var lastCleanFormatted: String? {
        guard let date = lastCleanDate else { return nil }
        return relativeDateFormatter.localizedString(for: date, relativeTo: Date())
    }

    static func record(cleaned: Int64, items: Int) {
        let newTotal = totalCleaned + cleaned
        defaults.set(Int(newTotal >> 32), forKey: Key.totalCleanedHigh)
        defaults.set(Int(newTotal & 0xFFFFFFFF), forKey: Key.totalCleanedLow)
        defaults.set(totalItems + items, forKey: Key.totalItems)
        defaults.set(totalScans + 1, forKey: Key.totalScans)
        defaults.set(Date(), forKey: Key.lastCleanDate)
    }
}
