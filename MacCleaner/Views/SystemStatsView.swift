import SwiftUI

struct SystemStatsView: View {
    @StateObject private var monitor = SystemMonitor()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // System info header
                systemHeader

                // Main gauges row
                HStack(spacing: 16) {
                    cpuGauge
                    memoryGauge
                    diskGauge
                    if monitor.battery.isPresent {
                        batteryGauge
                    }
                }

                // Detail cards
                HStack(spacing: 16) {
                    cpuDetail
                    memoryDetail
                }

                HStack(spacing: 16) {
                    gpuDetail
                    diskDetail
                }
            }
            .padding(24)
        }
        .onAppear { monitor.startMonitoring() }
        .onDisappear { monitor.stopMonitoring() }
    }

    // MARK: - System Header

    private var systemHeader: some View {
        HStack(spacing: 16) {
            Image(systemName: "desktopcomputer")
                .font(.system(size: 28))
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(monitor.cpuName)
                    .font(.headline)
                HStack(spacing: 12) {
                    Text(monitor.osVersion)
                    Text("\(monitor.coreCount) cores")
                    Text(FileSize.formatted(Int64(ProcessInfo.processInfo.physicalMemory)) + " RAM")
                    Text("Up \(monitor.uptime)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
    }

    // MARK: - Gauges

    private var cpuGauge: some View {
        gaugeCard(
            title: "CPU",
            value: monitor.cpu.total,
            color: cpuColor,
            subtitle: String(format: "%.0f%%", monitor.cpu.total)
        )
    }

    private var memoryGauge: some View {
        gaugeCard(
            title: "Memory",
            value: monitor.memory.usedPercentage * 100,
            color: memoryColor,
            subtitle: "\(FileSize.formatted(Int64(monitor.memory.used))) used"
        )
    }

    private var diskGauge: some View {
        gaugeCard(
            title: "Storage",
            value: monitor.disk.usedPercentage * 100,
            color: diskColor,
            subtitle: "\(FileSize.formatted(monitor.disk.freeSpace)) free"
        )
    }

    private var batteryGauge: some View {
        gaugeCard(
            title: monitor.battery.isCharging ? "Charging" : "Battery",
            value: Double(monitor.battery.percentage),
            color: batteryColor,
            subtitle: "\(monitor.battery.percentage)%"
        )
    }

    private func gaugeCard(title: String, value: Double, color: Color, subtitle: String) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: min(value / 100, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.5), value: value)

                Text(subtitle)
                    .font(.system(size: 11))
                    .fontWeight(.medium)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 4)
            }
            .frame(width: 80, height: 80)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
    }

    // MARK: - CPU Detail

    private var cpuDetail: some View {
        detailCard(title: "CPU", icon: "cpu") {
            detailRow("User", String(format: "%.1f%%", monitor.cpu.user))
            detailRow("System", String(format: "%.1f%%", monitor.cpu.system))
            detailRow("Idle", String(format: "%.1f%%", monitor.cpu.idle))
            detailRow("Cores", "\(monitor.coreCount)")
        }
    }

    // MARK: - Memory Detail

    private var memoryDetail: some View {
        detailCard(title: "Memory", icon: "memorychip") {
            detailRow("Active", FileSize.formatted(Int64(monitor.memory.active)))
            detailRow("Wired", FileSize.formatted(Int64(monitor.memory.wired)))
            detailRow("Compressed", FileSize.formatted(Int64(monitor.memory.compressed)))
            detailRow("Free", FileSize.formatted(Int64(monitor.memory.free)))
        }
    }

    // MARK: - GPU Detail

    private var gpuDetail: some View {
        detailCard(title: "GPU", icon: "gpu") {
            detailRow("Name", monitor.gpu.name)
            if monitor.gpu.vram > 0 {
                detailRow("VRAM", FileSize.formatted(Int64(monitor.gpu.vram)))
            }
        }
    }

    // MARK: - Disk Detail

    private var diskDetail: some View {
        detailCard(title: "Storage", icon: "internaldrive") {
            detailRow("Total", FileSize.formatted(monitor.disk.totalSpace))
            detailRow("Used", FileSize.formatted(monitor.disk.usedSpace))
            detailRow("Free", FileSize.formatted(monitor.disk.freeSpace))
            detailRow("Usage", String(format: "%.1f%%", monitor.disk.usedPercentage * 100))
        }
    }

    // MARK: - Helpers

    private func detailCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.callout)
                    .fontWeight(.medium)
            }

            VStack(spacing: 6) {
                content()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .monospacedDigit()
        }
    }

    // MARK: - Colors

    private var cpuColor: Color {
        let v = monitor.cpu.total
        if v > 80 { return .red }
        if v > 50 { return .orange }
        return .green
    }

    private var memoryColor: Color {
        let v = monitor.memory.usedPercentage
        if v > 0.85 { return .red }
        if v > 0.65 { return .orange }
        return .blue
    }

    private var diskColor: Color {
        let v = monitor.disk.usedPercentage
        if v > 0.9 { return .red }
        if v > 0.75 { return .orange }
        return .accentColor
    }

    private var batteryColor: Color {
        let v = monitor.battery.percentage
        if monitor.battery.isCharging { return .green }
        if v < 20 { return .red }
        if v < 50 { return .orange }
        return .green
    }
}
