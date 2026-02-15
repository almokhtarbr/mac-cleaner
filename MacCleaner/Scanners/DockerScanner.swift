import Foundation

struct DockerScanner: CleanerScanner {
    let category = CleanCategory.docker

    func scan() async -> [CleanableItem] {
        // Check if Docker is installed
        guard fm.fileExists(atPath: "/usr/local/bin/docker") ||
              fm.fileExists(atPath: "/opt/homebrew/bin/docker") ||
              fm.fileExists(atPath: "/Applications/Docker.app") else {
            return []
        }

        var items: [CleanableItem] = []

        // Docker disk usage via `docker system df`
        // We parse the output to show images, containers, build cache, volumes

        // Dangling images (no tag, not used by any container)
        let danglingImages = runDockerCommand(["images", "-f", "dangling=true", "--format", "{{.Size}}"])
        let danglingSize = parseDanglingImages()
        if danglingSize > 0 {
            items.append(CleanableItem(
                path: URL(fileURLWithPath: "/var/run/docker.sock"),
                name: "Dangling images",
                size: danglingSize,
                category: category
            ))
        }

        // Stopped containers
        let stoppedSize = parseStoppedContainers()
        if stoppedSize > 0 {
            items.append(CleanableItem(
                path: URL(fileURLWithPath: "/var/run/docker-containers"),
                name: "Stopped containers",
                size: stoppedSize,
                category: category
            ))
        }

        // Build cache
        let buildCacheSize = parseBuildCache()
        if buildCacheSize > 0 {
            items.append(CleanableItem(
                path: URL(fileURLWithPath: "/var/run/docker-buildcache"),
                name: "Build cache",
                size: buildCacheSize,
                category: category
            ))
        }

        // Docker Desktop VM disk (the big one)
        let vmDisk = home.appendingPathComponent("Library/Containers/com.docker.docker/Data")
        if fm.fileExists(atPath: vmDisk.path) {
            let size = FileSize.directoryFast(at: vmDisk)
            if size > 100_000_000 { // > 100MB
                items.append(CleanableItem(
                    path: vmDisk,
                    name: "Docker Desktop data",
                    size: size,
                    category: category,
                    isSelected: false  // Never auto-select — user may have important volumes
                ))
            }
        }

        return items.sorted { $0.size > $1.size }
    }

    // MARK: - Docker CLI helpers

    private func runDockerCommand(_ args: [String]) -> String {
        let process = Process()
        let pipe = Pipe()

        // Find docker binary
        let dockerPath: String
        if FileManager.default.fileExists(atPath: "/usr/local/bin/docker") {
            dockerPath = "/usr/local/bin/docker"
        } else if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/docker") {
            dockerPath = "/opt/homebrew/bin/docker"
        } else {
            return ""
        }

        process.executableURL = URL(fileURLWithPath: dockerPath)
        process.arguments = args
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }

    private func parseDanglingImages() -> Int64 {
        let output = runDockerCommand(["images", "-f", "dangling=true", "--format", "{{.Size}}"])
        return parseSizeLines(output)
    }

    private func parseStoppedContainers() -> Int64 {
        let output = runDockerCommand(["ps", "-a", "-f", "status=exited", "--format", "{{.Size}}"])
        return parseSizeLines(output)
    }

    private func parseBuildCache() -> Int64 {
        // `docker system df` gives a summary
        let output = runDockerCommand(["system", "df", "--format", "{{.Type}}\t{{.Reclaimable}}"])
        for line in output.split(separator: "\n") {
            let parts = line.split(separator: "\t")
            if parts.count >= 2 && parts[0] == "Build Cache" {
                return parseDockerSize(String(parts[1]))
            }
        }
        return 0
    }

    /// Parse "1.5GB", "200MB", "50kB" etc into bytes
    private func parseDockerSize(_ sizeStr: String) -> Int64 {
        // Remove parenthetical like "(100%)" and trim
        let cleaned = sizeStr.replacingOccurrences(of: #"\s*\(.*\)"#, with: "", options: .regularExpression).trimmingCharacters(in: .whitespaces)

        let units: [(String, Int64)] = [
            ("TB", 1_000_000_000_000),
            ("GB", 1_000_000_000),
            ("MB", 1_000_000),
            ("kB", 1_000),
            ("B", 1),
        ]

        for (unit, multiplier) in units {
            if cleaned.hasSuffix(unit) {
                let numStr = cleaned.dropLast(unit.count).trimmingCharacters(in: .whitespaces)
                if let num = Double(numStr) {
                    return Int64(num * Double(multiplier))
                }
            }
        }
        return 0
    }

    private func parseSizeLines(_ output: String) -> Int64 {
        var total: Int64 = 0
        for line in output.split(separator: "\n") {
            total += parseDockerSize(String(line))
        }
        return total
    }
}
