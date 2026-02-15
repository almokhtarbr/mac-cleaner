import SwiftUI

struct DashboardView: View {
    @StateObject private var vm = CleanerViewModel()

    var body: some View {
        VStack(spacing: 0) {
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
        .frame(minWidth: 680, minHeight: 520)
        .background(Color(nsColor: .windowBackgroundColor))
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

            Spacer()
        }
        .padding(40)
    }

    // MARK: - Results

    private var resultsView: some View {
        VStack(spacing: 0) {
            // Header
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

            // Category list
            ScrollView {
                VStack(spacing: 1) {
                    ForEach(vm.results.indices, id: \.self) { idx in
                        CategoryRow(result: $vm.results[idx], vm: vm)
                    }
                }
                .padding(.vertical, 8)
            }

            Divider()

            // Bottom bar
            HStack {
                Button("Rescan") {
                    vm.scan()
                }
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
                Button("Done") {
                    vm.reset()
                }
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
                        diskColor,
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

    private var diskColor: Color {
        let pct = vm.diskInfo.usedPercentage
        if pct > 0.9 { return .red }
        if pct > 0.75 { return .orange }
        return .accentColor
    }
}
