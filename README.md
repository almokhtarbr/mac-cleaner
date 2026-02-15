# MacCleaner

A free, open-source Mac cleaner with system monitoring. No subscriptions, no telemetry — scan, review, and clean. Built with Swift and SwiftUI.

## Download

- **[MacCleaner-v1.0.dmg](https://github.com/almokhtarbr/mac-cleaner/releases/latest)** — drag to Applications
- **[MacCleaner-v1.0.zip](https://github.com/almokhtarbr/mac-cleaner/releases/latest)** — extract and run

> Requires macOS 14.0 (Sonoma) or later.

## How to Use

### Cleaner Tab

1. **Scan** — click the Scan button to analyze your Mac for junk files
2. **Review** — expand each category to see individual files with sizes
3. **Select/Deselect** — uncheck anything you want to keep
4. **Clean** — click Clean to free disk space

### System Tab

Switch to the **System** tab (top-left) to see live hardware stats:

- CPU usage (user/system/idle breakdown, updates every 2s)
- Memory pressure (active, wired, compressed, free)
- GPU info (name + VRAM via Metal)
- Storage usage
- Battery status (if applicable)
- System uptime

### Stats

Click the **chart icon** (top-right) to view lifetime cleaning stats — total freed, items removed, number of cleans.

## What It Cleans

| Category | What | How | Size Range |
|----------|------|-----|------------|
| App Caches | `~/Library/Caches/*`, `~/.cache/*` | Permanent delete | 5–20 GB |
| Logs | `~/Library/Logs/*`, crash reports | Permanent delete | 500 MB–2 GB |
| Xcode | DerivedData, simulators, device support, archives | Permanent delete | 5–50 GB |
| Dev Tools | Homebrew, npm, yarn, pnpm, CocoaPods, Cargo, Gem, Gradle, Maven, pip, Go, NuGet | Permanent delete | 1–10 GB |
| Docker | Dangling images, stopped containers, build cache | Docker CLI | 1–20 GB |
| Project Leftovers | `node_modules`, `.venv`, `vendor`, `Pods`, `.build`, `target` in old projects | Permanent delete | 1–50 GB |
| Browser Cache | Chrome, Firefox, Safari, Brave, Edge, Opera | Permanent delete | 500 MB–5 GB |
| Large Files | Files > 100 MB in Downloads/Desktop/Documents | Move to Trash | Varies |
| Trash | Files already in `~/.Trash` | Empty Trash | Varies |

**Permanent delete** is used for files that regenerate automatically (caches, logs, build artifacts). Large files go to Trash so you can recover them.

## Safety

### Protected paths (never touched)

- iCloud: `~/Library/Mobile Documents/`, `~/Library/CloudStorage/`
- User data: Photos, Mail, Messages, Calendars, Contacts, Safari
- Credentials: Keychains, Cookies, `.ssh`, `.gnupg`, `.aws`, `.kube`
- App settings: Preferences, Application Support, Containers
- System: `/System/`, `/usr/`, `/bin/`, `/sbin/`, `/etc/`
- Media: Music, Pictures, Movies

### Safety features

- Path comparison is case-insensitive with symlink resolution
- Running apps are detected via `NSWorkspace` — their caches are skipped
- Docker Desktop data is never auto-selected
- Large files are never auto-selected
- Every operation is logged to `~/Library/Logs/MacCleaner/`

## Build from Source

```bash
git clone https://github.com/almokhtarbr/mac-cleaner.git
cd mac-cleaner
open MacCleaner.xcodeproj
# Cmd+R to build and run
```

### Create DMG

```bash
xcodebuild -scheme MacCleaner -configuration Release build \
  CONFIGURATION_BUILD_DIR=./build

mkdir -p /tmp/dmg && cp -R build/MacCleaner.app /tmp/dmg/ && \
  ln -sf /Applications /tmp/dmg/Applications

hdiutil create -volname "MacCleaner" -srcfolder /tmp/dmg \
  -ov -format UDZO dist/MacCleaner-v1.0.dmg

rm -rf /tmp/dmg
```

### Create ZIP

```bash
ditto -c -k --keepParent build/MacCleaner.app dist/MacCleaner-v1.0.zip
```

## Project Structure

```
MacCleaner/
├── MacCleanerApp.swift                 # App entry — single window
├── Views/
│   ├── DashboardView.swift             # Main screen: tabs, cleaner flow, stats
│   ├── CategoryRow.swift               # Expandable category with item checkboxes
│   └── SystemStatsView.swift           # Live CPU/memory/GPU/disk/battery dashboard
├── Models/
│   ├── CleanableItem.swift             # File model: path, size, category, selected
│   ├── CleanerViewModel.swift          # Scan/clean state machine
│   ├── CleanStats.swift                # Lifetime stats (UserDefaults)
│   ├── DiskInfo.swift                  # Disk space model
│   └── SystemMonitor.swift             # Live CPU/memory/GPU/battery via mach/Metal/IOKit
├── Scanners/
│   ├── Scanner.swift                   # Protocol + shared helpers
│   ├── CacheScanner.swift              # ~/Library/Caches/
│   ├── LogScanner.swift                # ~/Library/Logs/
│   ├── XcodeScanner.swift              # DerivedData, simulators, device support
│   ├── DevToolsScanner.swift           # Homebrew, npm, yarn, Cargo, Gem, etc.
│   ├── DockerScanner.swift             # Docker CLI: images, containers, build cache
│   ├── ProjectLeftoversScanner.swift   # node_modules, .venv, vendor in projects
│   ├── BrowserCacheScanner.swift       # Chrome, Firefox, Safari, Brave, Edge, Opera
│   ├── LargeFileScanner.swift          # Files > 100 MB
│   └── TrashScanner.swift              # ~/.Trash
├── Services/
│   ├── SafeDeleter.swift               # Delete logic: permanent vs trash vs docker CLI
│   ├── RunningAppChecker.swift         # Detect running apps before cleaning
│   ├── OperationLogger.swift           # Thread-safe daily log files
│   └── DiskAnalyzer.swift              # Disk space queries
└── Utilities/
    ├── FileSize.swift                  # ByteCountFormatter + directory size calculation
    ├── ProtectedPaths.swift            # 30+ hardcoded forbidden paths
    └── AppIdentifier.swift             # Resolve cache folders → app name + icon
```

## Tech Stack

- **Swift 5 + SwiftUI** — native macOS app, no Electron
- **FileManager** — file scanning, directory enumeration, deletion
- **Mach kernel APIs** — `host_statistics64()` for CPU and memory
- **Metal** — GPU detection via `MTLCreateSystemDefaultDevice()`
- **IOKit** — battery status via `IOPSCopyPowerSourcesInfo()`
- **NSWorkspace** — running app detection, trash operations
- **async/await** — non-blocking scans with cancellation support

## Roadmap

- [ ] Duplicate file finder (SHA256)
- [ ] App uninstaller (remove app + Library leftovers)
- [ ] iOS backup cleaner (`~/Library/Application Support/MobileSync/`)
- [ ] Startup items manager
- [ ] Visual disk map (treemap)
- [ ] Scheduled cleaning with notifications

## License

MIT
