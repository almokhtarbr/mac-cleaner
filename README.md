# CleanMyMac — Free & Open Source

A free, open-source Mac cleaner. No subscriptions, no BS — just scan, review, and clean. Built with Swift.

## Safety First

This app is designed to **never break anything**:

- **Nothing is auto-deleted** — every file must be reviewed and confirmed by you
- **Trash-first deletion** — files go to Trash, never permanent delete. You can always recover
- **Read-only scanning** — scanning never modifies or moves any file
- **iCloud untouched** — we skip all iCloud Drive, iCloud Photos, and iCloud-synced folders entirely
- **System files untouched** — never touches `/System/`, SIP-protected paths, or running app data
- **Running app detection** — warns you if an app is running before cleaning its cache
- **No root access by default** — only scans user-level paths unless you explicitly grant admin
- **Dry run mode** — see exactly what would happen before committing
- **Full operation log** — every action is logged so you can audit what happened

### What we NEVER touch

| Protected | Why |
|-----------|-----|
| `/System/` | SIP-protected, would break macOS |
| `~/Library/Mobile Documents/` | iCloud Drive sync folder |
| `~/Library/Photos/` | iCloud Photos library |
| `~/Library/CloudStorage/` | iCloud, Dropbox, Google Drive, OneDrive |
| `~/Library/Mail/` | Email data — too risky |
| `~/Library/Keychains/` | Passwords and keys |
| `~/Library/Cookies/` | Auth sessions |
| `~/Documents/` | User documents (only scanned for large files, never auto-selected) |
| `~/Desktop/` | User files (same — scan only, never auto-selected) |
| Running app caches | Checked via `NSRunningApplication` before cleanup |

## Features

### MVP (v1.0)

- **Dashboard** — disk space overview, quick scan summary
- **Cache Cleaner** — user app caches (`~/Library/Caches/`)
- **Log Cleaner** — app and system logs (`~/Library/Logs/`)
- **Xcode Cleaner** — DerivedData, old simulators, device support files
- **Dev Tools Cleaner** — Homebrew, npm, yarn, pnpm, CocoaPods, Cargo caches
- **Trash Emptier** — show Trash size, empty with confirmation
- **Large Files Finder** — scan for files >100MB, sort by size, user picks what to remove
- **Browser Cache** — Chrome, Firefox, Safari, Brave caches

### v2.0

- **Duplicate Finder** — SHA256 hash-based detection, preview before delete
- **App Uninstaller** — remove apps + their leftover Library files
- **Docker Cleanup** — unused images, volumes, build cache
- **iOS Backup Cleaner** — old device backups in MobileSync
- **Startup Items Manager** — disable/remove login items
- **Scheduled Cleaning** — weekly/monthly auto-scan with notification

### v3.0

- **Visual Disk Map** — treemap showing what's eating space
- **Smart Recommendations** — "You haven't opened X in 6 months"
- **Language File Cleaner** — remove unused .lproj localizations
- **Time Machine Snapshot Manager** — view and delete local snapshots

## Architecture

```
MacCleaner/
├── MacCleanerApp.swift              # App entry — single window app
├── Views/
│   ├── DashboardView.swift          # Main screen: disk stats + scan button
│   ├── ScanResultsView.swift        # Results: categories, files, sizes, checkboxes
│   ├── LargeFilesView.swift         # Large file browser with sorting
│   └── SettingsView.swift           # Excluded paths, safety toggles
├── Scanners/
│   ├── Scanner.swift                # Protocol: all scanners conform to this
│   ├── CacheScanner.swift           # ~/Library/Caches/
│   ├── LogScanner.swift             # ~/Library/Logs/
│   ├── XcodeScanner.swift           # DerivedData, simulators, device support
│   ├── DevToolsScanner.swift        # Homebrew, npm, yarn, pnpm, Cargo, Gem
│   ├── BrowserCacheScanner.swift    # Chrome, Firefox, Safari, Brave
│   └── LargeFileScanner.swift       # Files > 100MB
├── Models/
│   ├── CleanableItem.swift          # File/folder: path, size, category, selected
│   ├── ScanResult.swift             # Grouped results by category
│   └── DiskInfo.swift               # Total/used/free disk space
├── Services/
│   ├── DiskAnalyzer.swift           # Disk space queries
│   ├── SafeDeleter.swift            # Move to Trash (never permanent delete)
│   ├── RunningAppChecker.swift      # Check if app is running before cleaning
│   └── OperationLogger.swift        # Log every delete operation
└── Utilities/
    ├── FileSize.swift               # Human-readable file sizes
    ├── ProtectedPaths.swift         # Hardcoded list of NEVER-TOUCH paths
    └── AppIdentifier.swift          # Map cache folder → app name + icon
```

## Scan Categories & Paths

### Cache Cleaner
```
~/Library/Caches/*           → 5-20 GB typical
~/.cache/*                   → XDG cache
```
Safety: SAFE — apps regenerate caches on demand

### Log Cleaner
```
~/Library/Logs/*             → 500 MB - 2 GB
~/Library/Logs/DiagnosticReports/
```
Safety: SAFE — old logs serve no purpose

### Xcode Cleaner
```
~/Library/Developer/Xcode/DerivedData/          → 5-50 GB
~/Library/Developer/CoreSimulator/Devices/      → 5-20 GB
~/Library/Developer/Xcode/iOS DeviceSupport/    → 5-30 GB
~/Library/Developer/Xcode/Archives/             → 1-10 GB (CAUTION — show dates)
~/Library/Developer/DeveloperDiskImages/
```
Safety: SAFE for DerivedData + simulators. CAUTION for archives (may want to keep recent)

### Dev Tools Cleaner
```
~/Library/Caches/Homebrew/         → 500 MB - 5 GB
~/.npm/                            → 1-10 GB
~/Library/Caches/Yarn/             → 500 MB - 3 GB
~/.pnpm-store/                     → 1-5 GB
~/.cocoapods/repos/                → 500 MB - 2 GB
~/.cargo/registry/                 → 100 MB - 2 GB
~/.gem/                            → 100 MB - 1 GB
~/.gradle/caches/                  → 500 MB - 5 GB
~/.m2/repository/                  → 500 MB - 5 GB
```
Safety: SAFE — all re-download on demand

### Browser Cache
```
~/Library/Caches/Google/Chrome/
~/Library/Caches/Firefox/Profiles/
~/Library/Caches/com.apple.Safari/
~/Library/Caches/BraveSoftware/
```
Safety: SAFE — websites reload assets

### Large Files
Scan `~/` for files >100MB, excluding protected paths. Show sorted list, user picks.

## Tech Stack

- **Swift + SwiftUI** — native macOS app
- **FileManager** — file scanning and size calculation
- **CryptoKit** — SHA256 for duplicate detection (v2)
- **NSWorkspace** — move to Trash safely
- **NSRunningApplication** — detect running apps
- **DiskArbitration** — disk space info
- **Concurrency (async/await)** — non-blocking scans with progress

## Design Principles

1. **Scan is always free, always safe** — read-only operation
2. **User reviews everything** — no silent deletions
3. **Trash first** — `NSWorkspace.shared.recycle()`, never `FileManager.removeItem()`
4. **Skip if unsure** — if we can't determine safety, don't offer it
5. **Show the app name** — don't show raw paths, resolve to app names + icons
6. **Progress feedback** — scanning can take minutes, show real-time progress
7. **Respect running apps** — check `NSRunningApplication` before touching caches

## Install

### Build from source (macOS 14+)

```bash
git clone https://github.com/almokhtarbr/mac-cleaner.git
cd mac-cleaner
open MacCleaner.xcodeproj
# Cmd+R to build and run
```

## License

MIT — do whatever you want with it.
