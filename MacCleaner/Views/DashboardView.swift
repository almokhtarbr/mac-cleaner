import SwiftUI

enum AppTab: String, CaseIterable {
    case cleaner = "Cleaner"
    case system = "System"
}

struct DashboardView: View {
    @StateObject private var vm = CleanerViewModel()
    @State private var showStats = false
    @State private var activeTab: AppTab = .cleaner

    var body: some View {
        VStack(spacing: 0) {
            // Top bar: tabs + stats toggle
            HStack(spacing: 0) {
                // Tab picker
                HStack(spacing: 2) {
                    ForEach(AppTab.allCases, id: \.self) { tab in
                        Button(action: { withAnimation(.easeInOut(duration: 0.15)) { activeTab = tab } }) {
                            HStack(spacing: 5) {
                                Image(systemName: tab == .cleaner ? "trash" : "gauge.medium")
                                    .font(.caption)
                                Text(tab.rawValue)
                                    .font(.callout)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(activeTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                            .foregroundColor(activeTab == tab ? .accentColor : .secondary)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                .cornerRadius(8)

                Spacer()

                Button(action: { withAnimation { showStats.toggle() } }) {
                    Image(systemName: "chart.bar")
                        .font(.body)
                        .foregroundColor(showStats ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .help("Lifetime Clean Stats")
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 4)

            if showStats {
                cleanStatsPanel
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Content
            switch activeTab {
            case .cleaner:
                cleanerContent
            case .system:
                SystemStatsView()
            }
        }
        .frame(minWidth: 680, minHeight: 520)
        .background(Color(nsColor: .windowBackgroundColor))
        .animation(.easeInOut(duration: 0.2), value: showStats)
    }

    // MARK: - Cleaner Content

    private var cleanerContent: some View {
        Group {
            switch vm.state {
            case .idle:
                idleView
            case .scanning:
                scanningView
            case .results:
                resultsView
            case .cleaning:
                cleaningView
            case .done:
                doneView
            }
        }
    }

    // MARK: - Clean Stats Panel

    private var cleanStatsPanel: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Lifetime Clean Stats")
                    .font(.headline)
                Spacer()
            }

            if CleanStats.totalScans > 0 {
                HStack(spacing: 0) {
                    statCard(icon: "flame.fill", color: .orange,
                             value: FileSize.formatted(CleanStats.totalCleaned), label: "Total freed")
                    statCard(icon: "trash.fill", color: .red,
                             value: "\(CleanStats.totalItems)", label: "Items removed")
                    statCard(icon: "magnifyingglass", color: .blue,
                             value: "\(CleanStats.totalScans)", label: "Cleans done")
                    if let lastClean = CleanStats.lastCleanFormatted {
                        statCard(icon: "clock.fill", color: .green,
                                 value: lastClean, label: "Last clean")
                    }
                }
            } else {
                HStack {
                    Image(systemName: "chart.bar")
                        .font(.title2)
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No cleans yet — run your first scan to start tracking")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    private func statCard(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 32) {
            Spacer()

            diskGauge

            VStack(spacing: 8) {
                Text("MacCleaner")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                Text("Scan your Mac to find junk files, caches, and leftovers")
                    .foregroundColor(.secondary)
            }

            Button(action: { vm.scan() }) {
                Label("Scan", systemImage: "magnifyingglass")
                    .font(.title3)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .padding(40)
    }

    // MARK: - Scanning

    private var scanningView: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView()
                .scaleEffect(1.5)

            Text(vm.scanProgress)
                .font(.title3)
                .foregroundColor(.secondary)

            if !vm.results.isEmpty {
                Text("Found \(FileSize.formatted(vm.totalFoundSize)) so far...")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            Button("Cancel") {
                vm.cancelScan()
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)

            Spacer()
        }
        .padding(40)
    }

    // MARK: - Results

    private var resultsView: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scan Complete")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Found \(FileSize.formatted(vm.totalFoundSize)) across \(vm.results.count) categories")
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(FileSize.formatted(vm.totalSelectedSize))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                    Text("selected to clean")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)

            Divider()

            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(vm.results.indices, id: \.self) { idx in
                        CategoryRow(result: $vm.results[idx], vm: vm)
                    }
                }
                .padding(.vertical, 8)
            }

            Divider()

            HStack {
                Button("Rescan") { vm.scan() }
                    .buttonStyle(.bordered)

                Spacer()

                Text("\(vm.totalSelectedCount) items selected")
                    .foregroundColor(.secondary)
                    .font(.callout)

                Spacer()

                Button(action: { vm.clean() }) {
                    Label("Clean \(FileSize.formatted(vm.totalSelectedSize))", systemImage: "trash")
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(vm.totalSelectedCount == 0)
            }
            .padding(16)
        }
    }

    // MARK: - Cleaning

    private var cleaningView: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView()
                .scaleEffect(1.5)

            Text("Cleaning...")
                .font(.title3)
                .foregroundColor(.secondary)

            Text("Caches and logs are deleted permanently (they regenerate).\nUser files go to Trash.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(40)
    }

    // MARK: - Done

    private var doneView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(.green)

            VStack(spacing: 8) {
                Text("\(FileSize.formatted(vm.cleanedSize)) freed")
                    .font(.title)
                    .fontWeight(.semibold)

                let actualFreed = vm.diskAfter - vm.diskBefore
                if actualFreed > 0 {
                    Text("Disk space recovered: \(FileSize.formatted(actualFreed))")
                        .font(.callout)
                        .foregroundColor(.green)
                }

                Text("\(vm.cleanedCount) items cleaned")
                    .foregroundColor(.secondary)
            }

            if !vm.errors.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(vm.errors.count) items skipped:")
                        .font(.caption)
                        .foregroundColor(.orange)
                    ForEach(vm.errors.prefix(5), id: \.self) { error in
                        Text("- \(error)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            diskGauge

            HStack(spacing: 16) {
                Button("Done") { vm.reset() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }

            Spacer()
        }
        .padding(40)
    }

    // MARK: - Disk Gauge

    private var diskGauge: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: vm.diskInfo.usedPercentage)
                    .stroke(
                        diskGaugeColor,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.5), value: vm.diskInfo.usedPercentage)

                VStack(spacing: 2) {
                    Text(FileSize.formatted(vm.diskInfo.freeSpace))
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("free")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 120, height: 120)

            Text("\(FileSize.formatted(vm.diskInfo.usedSpace)) of \(FileSize.formatted(vm.diskInfo.totalSpace)) used")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var diskGaugeColor: Color {
        let pct = vm.diskInfo.usedPercentage
        if pct > 0.9 { return .red }
        if pct > 0.75 { return .orange }
        return .accentColor
    }
}
