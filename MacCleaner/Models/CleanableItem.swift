import Foundation
import AppKit

enum CleanCategory: String, CaseIterable, Identifiable {
    case caches = "App Caches"
    case logs = "Logs"
    case xcode = "Xcode"
    case devTools = "Dev Tools"
    case browser = "Browser Cache"
    case largeFiles = "Large Files"
    case trash = "Trash"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .caches: return "folder.badge.gearshape"
        case .logs: return "doc.text"
        case .xcode: return "hammer"
        case .devTools: return "terminal"
        case .browser: return "globe"
        case .largeFiles: return "externaldrive"
        case .trash: return "trash"
        }
    }

    var description: String {
        switch self {
        case .caches: return "Temporary app data that regenerates automatically"
        case .logs: return "Diagnostic logs and crash reports"
        case .xcode: return "DerivedData, old simulators, device support"
        case .devTools: return "Homebrew, npm, yarn, CocoaPods, Cargo caches"
        case .browser: return "Chrome, Firefox, Safari, Brave cached data"
        case .largeFiles: return "Files larger than 100 MB"
        case .trash: return "Files already in Trash"
        }
    }
}

struct CleanableItem: Identifiable, Hashable {
    let id: String
    let path: URL
    let name: String
    let size: Int64
    let category: CleanCategory
    let appName: String?
    let appIcon: NSImage?
    var isSelected: Bool

    init(path: URL, name: String, size: Int64, category: CleanCategory, appName: String? = nil, appIcon: NSImage? = nil, isSelected: Bool = true) {
        self.id = path.path
        self.path = path
        self.name = name
        self.size = size
        self.category = category
        self.appName = appName
        self.appIcon = appIcon
        self.isSelected = isSelected
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CleanableItem, rhs: CleanableItem) -> Bool {
        lhs.id == rhs.id
    }
}

struct ScanResult {
    let category: CleanCategory
    var items: [CleanableItem]

    var totalSize: Int64 {
        items.reduce(0) { $0 + $1.size }
    }

    var selectedSize: Int64 {
        items.filter(\.isSelected).reduce(0) { $0 + $1.size }
    }

    var selectedCount: Int {
        items.filter(\.isSelected).count
    }
}
