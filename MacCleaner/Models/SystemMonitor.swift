import Foundation
import IOKit.ps
import Metal

// MARK: - CPU

struct CPUUsage {
    let system: Double
    let user: Double
    let idle: Double
    var total: Double { system + user }
}

// MARK: - Memory

struct MemoryUsage {
    let total: UInt64        // bytes
    let used: UInt64
    let active: UInt64
    let inactive: UInt64
    let wired: UInt64
    let compressed: UInt64
    let free: UInt64

    var usedPercentage: Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total)
    }
}

// MARK: - GPU

struct GPUInfo {
    let name: String
    let vram: UInt64   // bytes, 0 for integrated
}

// MARK: - Battery

struct BatteryInfo {
    let percentage: Int
    let isCharging: Bool
    let isPresent: Bool
}

// MARK: - Monitor

@MainActor
class SystemMonitor: ObservableObject {
    @Published var cpu = CPUUsage(system: 0, user: 0, idle: 100)
    @Published var memory = MemoryUsage(total: 0, used: 0, active: 0, inactive: 0, wired: 0, compressed: 0, free: 0)
    @Published var gpu = GPUInfo(name: "Unknown", vram: 0)
    @Published var battery = BatteryInfo(percentage: 100, isCharging: false, isPresent: false)
    @Published var disk = DiskInfo(totalSpace: 0, usedSpace: 0, freeSpace: 0)
    @Published var cpuName: String = "Unknown"
    @Published var coreCount: Int = 0
    @Published var osVersion: String = "macOS"
    @Published var uptime: String = ""

    private var timer: Timer?
    private var prevCPUInfo: host_cpu_load_info?

    init() {
        cpuName = Self.getCPUName()
        coreCount = ProcessInfo.processInfo.processorCount
        osVersion = Self.getOSVersion()
        gpu = Self.getGPUInfo()
        refresh()
    }

    func startMonitoring() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func refresh() {
        cpu = Self.getCPUUsage(previous: &prevCPUInfo)
        memory = Self.getMemoryUsage()
        battery = Self.getBatteryInfo()
        disk = DiskInfo.current()
        uptime = Self.getUptime()
    }

    // MARK: - CPU Name

    private static func getCPUName() -> String {
        var size: size_t = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var name = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &name, &size, nil, 0)
        let result = String(cString: name)
        return result.isEmpty ? "Apple Silicon" : result
    }

    // MARK: - CPU Usage

    private static func getCPUUsage(previous: inout host_cpu_load_info?) -> CPUUsage {
        var loadInfo = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &loadInfo) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return CPUUsage(system: 0, user: 0, idle: 100)
        }

        let user = Double(loadInfo.cpu_ticks.0)
        let system = Double(loadInfo.cpu_ticks.1)
        let idle = Double(loadInfo.cpu_ticks.2)
        let nice = Double(loadInfo.cpu_ticks.3)

        if let prev = previous {
            let dUser = user - Double(prev.cpu_ticks.0)
            let dSystem = system - Double(prev.cpu_ticks.1)
            let dIdle = idle - Double(prev.cpu_ticks.2)
            let dNice = nice - Double(prev.cpu_ticks.3)
            let totalDelta = dUser + dSystem + dIdle + dNice

            previous = loadInfo

            if totalDelta > 0 {
                return CPUUsage(
                    system: (dSystem / totalDelta) * 100,
                    user: ((dUser + dNice) / totalDelta) * 100,
                    idle: (dIdle / totalDelta) * 100
                )
            }
        }

        previous = loadInfo
        let total = user + system + idle + nice
        guard total > 0 else { return CPUUsage(system: 0, user: 0, idle: 100) }

        return CPUUsage(
            system: (system / total) * 100,
            user: ((user + nice) / total) * 100,
            idle: (idle / total) * 100
        )
    }

    // MARK: - Memory

    private static func getMemoryUsage() -> MemoryUsage {
        let totalRAM = ProcessInfo.processInfo.physicalMemory

        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return MemoryUsage(total: totalRAM, used: 0, active: 0, inactive: 0, wired: 0, compressed: 0, free: totalRAM)
        }

        let pageSize = UInt64(vm_kernel_page_size)
        let active = UInt64(stats.active_count) * pageSize
        let inactive = UInt64(stats.inactive_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        let used = active + wired + compressed

        return MemoryUsage(
            total: totalRAM,
            used: used,
            active: active,
            inactive: inactive,
            wired: wired,
            compressed: compressed,
            free: totalRAM - used
        )
    }

    // MARK: - GPU

    private static func getGPUInfo() -> GPUInfo {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return GPUInfo(name: "Unknown", vram: 0)
        }
        let vram = UInt64(device.recommendedMaxWorkingSetSize)
        return GPUInfo(name: device.name, vram: vram)
    }

    // MARK: - Battery

    private static func getBatteryInfo() -> BatteryInfo {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [Any],
              let first = sources.first,
              let desc = IOPSGetPowerSourceDescription(snapshot, first as CFTypeRef)?.takeUnretainedValue() as? [String: Any]
        else {
            return BatteryInfo(percentage: 100, isCharging: false, isPresent: false)
        }

        let capacity = desc[kIOPSCurrentCapacityKey] as? Int ?? 100
        let isCharging = (desc[kIOPSIsChargingKey] as? Bool) ?? false

        return BatteryInfo(percentage: capacity, isCharging: isCharging, isPresent: true)
    }

    // MARK: - OS Version

    private static func getOSVersion() -> String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "macOS \(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }

    // MARK: - Uptime

    private static func getUptime() -> String {
        let seconds = ProcessInfo.processInfo.systemUptime
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours >= 24 {
            let days = hours / 24
            let remHours = hours % 24
            return "\(days)d \(remHours)h"
        }
        return "\(hours)h \(minutes)m"
    }
}
