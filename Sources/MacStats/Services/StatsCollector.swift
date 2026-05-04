import Foundation
import Combine
import Darwin
import Cocoa
import IOKit.ps

class StatsCollector: ObservableObject {
    @Published var cpuUsage: Double = 0.0
    @Published var memoryUsage: Double = 0.0
    @Published var diskUsage: Double = 0.0
    @Published var networkUpload: Double = 0.0
    @Published var networkDownload: Double = 0.0
    @Published var gpuUsage: Double = 0.0
    @Published var gpuTemp: Double = 0.0

    // Battery
    @Published var batteryLevel: Double = 1.0
    @Published var batteryCharging: Bool = false
    @Published var batteryTimeRemaining: String = "--"

    // System
    @Published var systemUptime: String = ""
    @Published var cpuFrequencyMode: String = ""

    // Memory extras
    @Published var memoryPressure: String = "Normal"
    @Published var swapUsed: Double = 0.0
    @Published var swapTotal: Double = 0.0

    // Disk details
    @Published var diskReadSpeed: Double = 0.0
    @Published var diskWriteSpeed: Double = 0.0
    @Published var diskTotal: Int64 = 0
    @Published var diskUsed: Int64 = 0

    // Per-core + top processes
    @Published var cpuPerCore: [Double] = []
    @Published var topCpuProcesses: [AppProcess] = []
    @Published var topMemProcesses: [AppProcess] = []

    // --- Histories (60 points = 2 min at 2s intervals) ---
    @Published var cpuHistory: [Double] = Array(repeating: 0.0, count: 60)
    @Published var memHistory: [Double] = Array(repeating: 0.0, count: 60)
    @Published var networkDownloadHistory: [Double] = Array(repeating: 0.0, count: 60)
    @Published var networkUploadHistory: [Double] = Array(repeating: 0.0, count: 60)
    @Published var diskReadHistory: [Double] = Array(repeating: 0.0, count: 60)
    @Published var diskWriteHistory: [Double] = Array(repeating: 0.0, count: 60)
    @Published var gpuHistory: [Double] = Array(repeating: 0.0, count: 60)

    struct MemoryDetails {
        var wired: Double
        var active: Double
        var compressed: Double
        var free: Double
        var total: Double
    }
    @Published var memoryDetails: MemoryDetails = MemoryDetails(wired: 0, active: 0, compressed: 0, free: 0, total: 0)

    struct AppProcess: Identifiable {
        let id = UUID()
        let pid: Int
        let name: String
        let usage: Double
        let icon: NSImage?
    }

    // --- Cached IP (avoid repeated syscall) ---
    private var cachedIP: String = ""
    private var lastIPCheck: TimeInterval = 0

    // --- Private state ---
    private var prevCpuInfo: processor_info_array_t?
    @Published var prevCpuInfoCount: mach_msg_type_number_t = 0
    private var lastDiskMB: Double?
    private var lastDiskCheckTime: TimeInterval = 0
    private var lastNetworkInfo: (upload: UInt64, download: UInt64)?

    // --- CRITICAL: Store timers as strong references on main RunLoop ---
    private var fastTimer: Timer?   // 2s  — CPU, Mem, Network, Disk
    private var gpuTimer: Timer?    // 8s  — GPU (ioreg process spawn, expensive)
    private var slowTimer: Timer?   // 10s — Processes (ps spawn, expensive) + Swap
    private var sysTimer: Timer?    // 15s — Battery, uptime, IP (cheapest)

    init() {
        startCollecting()
        registerSleepWakeNotifications()
    }

    func startCollecting() {
        // Fast: CPU, Memory, Network, Disk I/O
        fastTimer = Timer(timeInterval: 2.0, repeats: true) { [weak self] _ in
            autoreleasepool { self?.collectFastStats() }
        }
        RunLoop.main.add(fastTimer!, forMode: .common)

        // GPU: spawn ioreg — throttled to save CPU
        gpuTimer = Timer(timeInterval: 8.0, repeats: true) { [weak self] _ in
            self?.collectGPUStats()
        }
        RunLoop.main.add(gpuTimer!, forMode: .common)

        // Slow: `ps` process listing + swap (heavier)
        slowTimer = Timer(timeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.collectProcesses()
            self?.collectSwapInfo()
        }
        RunLoop.main.add(slowTimer!, forMode: .common)

        // System info: battery, uptime — very cheap, least frequent
        sysTimer = Timer(timeInterval: 15.0, repeats: true) { [weak self] _ in
            self?.collectBatteryInfo()
            self?.collectSystemInfo()
        }
        RunLoop.main.add(sysTimer!, forMode: .common)

        // Seed on launch (no disk history yet)
        collectFastStats()
        collectBatteryInfo()
        collectSystemInfo()
        collectSwapInfo()
    }

    // MARK: - Sleep / Wake
    private func registerSleepWakeNotifications() {
        // Tell macOS this process must not be auto-terminated.
        // Doing it programmatically is more reliable than Info.plist alone for LSUIElement agents.
        ProcessInfo.processInfo.disableAutomaticTermination("MacStats monitoring")

        let wsnc = NSWorkspace.shared.notificationCenter
        // Stop collection BEFORE sleep so no background ioreg/iostat process
        // gets interrupted mid-execution (which causes a crash on wake).
        wsnc.addObserver(self, selector: #selector(handleWillSleep),
                         name: NSWorkspace.willSleepNotification, object: nil)
        wsnc.addObserver(self, selector: #selector(handleWake),
                         name: NSWorkspace.didWakeNotification, object: nil)
    }

    @objc private func handleWillSleep() {
        // Invalidate all timers before sleep. This ensures no spawned subprocess
        // (ioreg, iostat, ps) is in-flight when the system suspends — those would
        // be killed by the OS and their pipe reads would throw, crashing the app.
        fastTimer?.invalidate(); fastTimer = nil
        gpuTimer?.invalidate();  gpuTimer = nil
        slowTimer?.invalidate(); slowTimer = nil
        sysTimer?.invalidate();  sysTimer = nil
    }

    @objc private func handleWake() {
        // Reset delta-based baselines — CPU/network/disk counters advanced
        // during sleep so the first sample after wake would show a false spike.
        prevCpuInfo?.deallocate()
        prevCpuInfo = nil
        prevCpuInfoCount = 0
        lastNetworkInfo = nil
        lastDiskMB = nil
        lastDiskCheckTime = 0
        lastIPCheck = 0   // IP may have changed after reconnecting

        // Restart all timers fresh (startCollecting creates new timers)
        startCollecting()
    }

    // MARK: - Fast Stats (2s)
    private func collectFastStats() {
        cpuUsage = getCPUUsage()
        memoryUsage = getMemoryUsage()
        diskUsage = getDiskUsage()
        getNetworkUsage()
        collectDiskIO()

        // Append histories (on main — already here)
        cpuHistory.append(cpuUsage)
        if cpuHistory.count > 60 { cpuHistory.removeFirst() }
        memHistory.append(memoryUsage)
        if memHistory.count > 60 { memHistory.removeFirst() }
    }

    // MARK: - GPU (8s)
    private func collectGPUStats() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }

            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/sbin/ioreg")
            task.arguments = ["-c", "IOAccelerator", "-r", "-d", "1"]
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = Pipe()

            do { try task.run(); task.waitUntilExit() } catch { return }

            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

            var usage: Double = 0
            let patterns = ["\"Device Utilization %\"=(\\d+)", "\"Tiler Utilization %\"=(\\d+)"]
            for pattern in patterns {
                if let range = output.range(of: pattern, options: .regularExpression) {
                    if let val = Double(String(output[range]).split(separator: "=").last ?? "") {
                        usage = val / 100.0
                        break
                    }
                }
            }

            let state = ProcessInfo.processInfo.thermalState
            let baseTemp: Double = state == .nominal ? 40 : state == .fair ? 55 : state == .serious ? 75 : 90
            let target = baseTemp + (usage * 30.0)

            DispatchQueue.main.async {
                self.gpuUsage = usage
                self.gpuTemp += (target - self.gpuTemp) * 0.2
                self.gpuHistory.append(usage)
                if self.gpuHistory.count > 60 { self.gpuHistory.removeFirst() }
            }
        }
    }

    // MARK: - Processes (10s)
    func collectProcesses() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            autoreleasepool {
                let cpu = self.getTopProcesses(sortKey: "%cpu")
                let mem = self.getTopProcesses(sortKey: "%mem")
                DispatchQueue.main.async {
                    self.topCpuProcesses = cpu
                    self.topMemProcesses = mem
                }
            }
        }
    }

    // MARK: - Swap (10s — lightweight sysctl)
    func collectSwapInfo() {
        var xswUsage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        if sysctlbyname("vm.swapusage", &xswUsage, &size, nil, 0) == 0 {
            swapUsed = Double(xswUsage.xsu_used)
            swapTotal = Double(xswUsage.xsu_total)
        }
    }

    // MARK: - Battery (15s)
    private func collectBatteryInfo() {
        let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] ?? []
        for source in sources {
            guard let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else { continue }
            if let cap = info[kIOPSCurrentCapacityKey] as? Int, let max = info[kIOPSMaxCapacityKey] as? Int, max > 0 {
                batteryLevel = Double(cap) / Double(max)
            }
            batteryCharging = (info[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue
            if let tte = info[kIOPSTimeToEmptyKey] as? Int, tte > 0 {
                batteryTimeRemaining = tte >= 60 ? "\(tte/60)h \(tte%60)m" : "\(tte)m"
            } else if let ttf = info[kIOPSTimeToFullChargeKey] as? Int, ttf > 0 {
                batteryTimeRemaining = "~\(ttf >= 60 ? "\(ttf/60)h " : "")\(ttf%60)m to full"
            } else {
                batteryTimeRemaining = batteryCharging ? "Calculating..." : "--"
            }
        }
    }

    // MARK: - System Info (15s)
    private func collectSystemInfo() {
        let s = Int(ProcessInfo.processInfo.systemUptime)
        let d = s / 86400, h = (s % 86400) / 3600, m = (s % 3600) / 60
        systemUptime = d > 0 ? "\(d)d \(h)h \(m)m" : h > 0 ? "\(h)h \(m)m" : "\(m)m"

        switch ProcessInfo.processInfo.thermalState {
        case .nominal:  cpuFrequencyMode = "Performance"
        case .fair:     cpuFrequencyMode = "Balanced"
        case .serious:  cpuFrequencyMode = "Throttled"
        case .critical: cpuFrequencyMode = "Critical"
        @unknown default: cpuFrequencyMode = "Unknown"
        }
    }

    // MARK: - CPU
    private func getCPUUsage() -> Double {
        let host = mach_host_self()
        var cpuInfo: processor_info_array_t!
        var cpuInfoCount: mach_msg_type_number_t = 0
        var numCPUs: mach_msg_type_number_t = 0
        guard host_processor_info(host, PROCESSOR_CPU_LOAD_INFO, &numCPUs, &cpuInfo, &cpuInfoCount) == KERN_SUCCESS else { return 0 }

        var totalUser: UInt32 = 0, totalSystem: UInt32 = 0, totalNice: UInt32 = 0, totalIdle: UInt32 = 0
        var newPerCore: [Double] = []

        if let prev = prevCpuInfo {
            for i in 0..<Int(numCPUs) {
                let base = i * Int(CPU_STATE_MAX)
                let u = cpuInfo[base + Int(CPU_STATE_USER)]   - prev[base + Int(CPU_STATE_USER)]
                let s = cpuInfo[base + Int(CPU_STATE_SYSTEM)] - prev[base + Int(CPU_STATE_SYSTEM)]
                let n = cpuInfo[base + Int(CPU_STATE_NICE)]   - prev[base + Int(CPU_STATE_NICE)]
                let id = cpuInfo[base + Int(CPU_STATE_IDLE)]  - prev[base + Int(CPU_STATE_IDLE)]
                let t = u + s + n + id
                newPerCore.append(t > 0 ? Double(u + s + n) / Double(t) : 0)
                totalUser += UInt32(u); totalSystem += UInt32(s); totalNice += UInt32(n); totalIdle += UInt32(id)
            }
        }
        cpuPerCore = newPerCore

        let newPrev = UnsafeMutablePointer<integer_t>.allocate(capacity: Int(cpuInfoCount))
        newPrev.initialize(from: cpuInfo, count: Int(cpuInfoCount))
        prevCpuInfo?.deallocate()
        prevCpuInfo = newPrev
        prevCpuInfoCount = cpuInfoCount

        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(Int(cpuInfoCount) * MemoryLayout<integer_t>.stride))

        let total = totalUser + totalSystem + totalNice + totalIdle
        return total == 0 ? 0 : Double(totalUser + totalSystem + totalNice) / Double(total)
    }

    // MARK: - Memory
    private func getMemoryUsage() -> Double {
        var stats = vm_statistics64()
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &size)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }

        let pg = UInt64(vm_kernel_page_size)
        let active     = Double(UInt64(stats.active_count)     * pg)
        let wired      = Double(UInt64(stats.wire_count)       * pg)
        let compressed = Double(UInt64(stats.compressor_page_count) * pg)
        let free       = Double(UInt64(stats.free_count)       * pg)
        let physical   = Double(ProcessInfo.processInfo.physicalMemory)

        memoryDetails = MemoryDetails(wired: wired, active: active, compressed: compressed, free: free, total: physical)
        memoryPressure = (compressed / max(physical, 1)) > 0.3 ? "High" : (compressed / max(physical, 1)) > 0.15 ? "Medium" : "Normal"

        return (active + wired + compressed) / physical
    }

    // MARK: - Disk Usage
    private func getDiskUsage() -> Double {
        let url = URL(fileURLWithPath: "/")
        guard let vals = try? url.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey]),
              let total = vals.volumeTotalCapacity, let avail = vals.volumeAvailableCapacity else { return 0 }
        diskTotal = Int64(total)
        diskUsed  = Int64(total) - Int64(avail)
        return 1.0 - Double(avail) / Double(total)
    }

    // MARK: - Disk I/O
    private func collectDiskIO() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            let task = Process()
            task.launchPath = "/usr/sbin/iostat"
            task.arguments = ["-Id"]
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = Pipe()
            do { try task.run(); task.waitUntilExit() } catch { return }

            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let lines = output.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .newlines)
            guard let last = lines.last,
                  let mb = Double(last.split(separator: " ", omittingEmptySubsequences: true).last ?? "") else { return }

            let now = Date().timeIntervalSince1970
            if let prev = self.lastDiskMB, self.lastDiskCheckTime > 0 {
                let dt = now - self.lastDiskCheckTime
                let bytesPerSec = dt > 0 ? max(0, (mb - prev) / dt) * 1_048_576 : 0
                DispatchQueue.main.async {
                    self.diskReadSpeed = bytesPerSec
                    self.diskReadHistory.append(bytesPerSec)
                    if self.diskReadHistory.count > 60 { self.diskReadHistory.removeFirst() }
                    self.diskWriteHistory.append(0)
                    if self.diskWriteHistory.count > 60 { self.diskWriteHistory.removeFirst() }
                }
            }
            self.lastDiskMB = mb
            self.lastDiskCheckTime = now
        }
    }

    // MARK: - Network
    private func getNetworkUsage() {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return }
        defer { freeifaddrs(ifaddr) }

        var up: UInt64 = 0, down: UInt64 = 0
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            guard let iface = ptr?.pointee,
                  (iface.ifa_flags & UInt32(IFF_LOOPBACK)) == 0,
                  (iface.ifa_flags & UInt32(IFF_UP)) != 0,
                  (iface.ifa_flags & UInt32(IFF_RUNNING)) != 0,
                  iface.ifa_addr.pointee.sa_family == UInt8(AF_LINK),
                  let data = iface.ifa_data?.assumingMemoryBound(to: if_data.self) else { continue }
            down += UInt64(data.pointee.ifi_ibytes)
            up   += UInt64(data.pointee.ifi_obytes)
        }

        if let last = lastNetworkInfo {
            networkUpload   = Double(up - last.upload)
            networkDownload = Double(down - last.download)
            networkDownloadHistory.append(networkDownload)
            if networkDownloadHistory.count > 60 { networkDownloadHistory.removeFirst() }
            networkUploadHistory.append(networkUpload)
            if networkUploadHistory.count > 60 { networkUploadHistory.removeFirst() }
        }
        lastNetworkInfo = (up, down)
    }

    // MARK: - Local IP (cached — avoids repeated syscall on every render)
    func getLocalIP() -> String {
        let now = Date().timeIntervalSince1970
        if !cachedIP.isEmpty && now - lastIPCheck < 30 { return cachedIP }

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return cachedIP.isEmpty ? "Unknown" : cachedIP }
        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            guard let iface = ptr?.pointee,
                  iface.ifa_addr.pointee.sa_family == UInt8(AF_INET),
                  String(cString: iface.ifa_name) == "en0" else { continue }
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(iface.ifa_addr, socklen_t(iface.ifa_addr.pointee.sa_len),
                        &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
            cachedIP = String(cString: hostname)
            break
        }
        lastIPCheck = now
        return cachedIP.isEmpty ? "Unknown" : cachedIP
    }

    // MARK: - Top Processes
    private func getTopProcesses(sortKey: String) -> [AppProcess] {
        let task = Process()
        task.launchPath = "/bin/ps"
        // Parse more candidates since we'll filter strictly — use pid,pcpu,pmem only (no comm needed)
        task.arguments = sortKey == "%mem" ? ["-Amco", "pid,pcpu,pmem"] : ["-Arco", "pid,pcpu,pmem"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        do { try task.run() } catch { return [] }

        let sema = DispatchSemaphore(value: 0)
        task.terminationHandler = { _ in sema.signal() }
        if sema.wait(timeout: .now() + 3) == .timedOut { task.terminate() }

        guard let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) else { return [] }

        // Get all running .regular apps once — these are exactly the apps shown in Dock/App Switcher.
        // Helpers, renderers, daemons all have .accessory or .prohibited policy and are excluded automatically.
        let regularApps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular
        }
        let regularPIDs = Dictionary(uniqueKeysWithValues: regularApps.map { (Int($0.processIdentifier), $0) })

        var results: [AppProcess] = []
        var seen = Set<Int>() // deduplicate by PID (ps may list same pid across threads)

        for line in output.components(separatedBy: .newlines).dropFirst() {
            if results.count >= 5 { break }
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 3,
                  let pid = Int(parts[0]),
                  let cpu = Double(parts[1]),
                  let mem = Double(parts[2]),
                  !seen.contains(pid),
                  let app = regularPIDs[pid] else { continue }

            seen.insert(pid)
            let val = sortKey == "%mem" ? mem : cpu
            results.append(AppProcess(pid: pid, name: app.localizedName ?? "Unknown", usage: val, icon: app.icon))
        }
        return results
    }

    deinit {
        fastTimer?.invalidate()
        gpuTimer?.invalidate()
        slowTimer?.invalidate()
        sysTimer?.invalidate()
        prevCpuInfo?.deallocate()
    }
}
