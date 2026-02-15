import Foundation
import SwiftUI

enum AppState {
    case idle
    case scanning
    case results
    case cleaning
    case done
}

@MainActor
class CleanerViewModel: ObservableObject {
    @Published var state: AppState = .idle
    @Published var diskInfo: DiskInfo = DiskInfo.current()
    @Published var results: [ScanResult] = []
    @Published var scanProgress: String = ""
    @Published var cleanedSize: Int64 = 0
    @Published var cleanedCount: Int = 0
    @Published var errors: [String] = []
    @Published var diskBefore: Int64 = 0
    @Published var diskAfter: Int64 = 0

    private let scanners: [CleanerScanner] = [
        CacheScanner(),
        LogScanner(),
        XcodeScanner(),
        DevToolsScanner(),
        DockerScanner(),
        ProjectLeftoversScanner(),
        BrowserCacheScanner(),
        LargeFileScanner(),
        TrashScanner(),
    ]

    var totalFoundSize: Int64 {
        results.reduce(0) { $0 + $1.totalSize }
    }

    var totalSelectedSize: Int64 {
        results.reduce(0) { $0 + $1.selectedSize }
    }

    var totalSelectedCount: Int {
        results.reduce(0) { $0 + $1.selectedCount }
    }

    func scan() {
        state = .scanning
        results = []
        errors = []

        Task {
            for scanner in scanners {
                scanProgress = "Scanning \(scanner.category.rawValue)..."
                let items = await scanner.scan()
                if !items.isEmpty {
                    results.append(ScanResult(category: scanner.category, items: items))
                }
            }
            diskInfo = DiskInfo.current()
            state = results.isEmpty ? .idle : .results
            scanProgress = ""
        }
    }

    func toggleItem(category: CleanCategory, itemID: String) {
        guard let catIdx = results.firstIndex(where: { $0.category == category }) else { return }
        guard let itemIdx = results[catIdx].items.firstIndex(where: { $0.id == itemID }) else { return }
        results[catIdx].items[itemIdx].isSelected.toggle()
    }

    func toggleAllInCategory(_ category: CleanCategory, selected: Bool) {
        guard let idx = results.firstIndex(where: { $0.category == category }) else { return }
        for i in results[idx].items.indices {
            // Don't auto-select large files or archives
            if selected && (results[idx].items[i].category == .largeFiles) { continue }
            results[idx].items[i].isSelected = selected
        }
    }

    func clean() {
        state = .cleaning
        diskBefore = diskInfo.freeSpace
        let selectedItems = results.flatMap { $0.items.filter(\.isSelected) }

        Task.detached { [weak self] in
            let result = SafeDeleter.clean(items: selectedItems)
            await MainActor.run {
                guard let self else { return }
                self.cleanedSize = result.freed
                self.cleanedCount = result.deleted
                self.errors = result.errors
                self.diskInfo = DiskInfo.current()
                self.diskAfter = self.diskInfo.freeSpace
                self.state = .done
            }
        }
    }

    func emptyTrash() {
        Task.detached {
            SafeDeleter.emptyTrash()
            await MainActor.run { [weak self] in
                self?.diskInfo = DiskInfo.current()
            }
        }
    }

    func reset() {
        state = .idle
        results = []
        cleanedSize = 0
        cleanedCount = 0
        errors = []
        diskInfo = DiskInfo.current()
    }
}
