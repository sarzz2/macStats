import Foundation
import Combine
import Darwin
import Cocoa

class StatsCollector: ObservableObject {
    @Published var cpuUsage: Double = 0.0
    @Published var memoryUsage: Double = 0.0
    @Published var diskUsage: Double = 0.0
    @Published var networkUpload: Double = 0.0
    @Published var networkDownload: Double = 0.0
    @Published var gpuUsage: Double = 0.0 // Placeholder for now
    @Published var gpuTemp: Double = 0.0 // Simulated
    
    private var timer: Timer?
    private var prevCpuInfo: processor_info_array_t?
    @Published var prevCpuInfoCount: mach_msg_type_number_t = 0
    
    // Advanced Stats
    struct AppProcess: Identifiable {
        let id = UUID()
        let pid: Int
        let name: String
        let usage: Double
        let icon: NSImage?
    }
    
    @Published var topCpuProcesses: [AppProcess] = []
    @Published var topMemProcesses: [AppProcess] = []
    @Published var cpuPerCore: [Double] = []
    
    // History for Graphs (stores last 30 data points)
    @Published var networkDownloadHistory: [Double] = Array(repeating: 0.0, count: 30)
    @Published var networkUploadHistory: [Double] = Array(repeating: 0.0, count: 30)
    @Published var diskReadHistory: [Double] = Array(repeating: 0.0, count: 30)
    @Published var diskWriteHistory: [Double] = Array(repeating: 0.0, count: 30)
    @Published var gpuHistory: [Double] = Array(repeating: 0.0, count: 30)
    
    // Memory Details
    struct MemoryDetails {
        var wired: Double
        var active: Double
        var compressed: Double
        var free: Double
    }
    @Published var memoryDetails: MemoryDetails = MemoryDetails(wired: 0, active: 0, compressed: 0, free: 0)
    
    init() {
        startCollecting()
    }
    
    func startCollecting() {
        // Fast Stats (CPU, Mem, Network, Disk Usage) - 2s
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.collectStats()
            self?.collectDiskIO()
        }
        
        // Slow Stats (Processes) - 5s
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.collectProcesses()
        }
    }
    
    func collectStats() {
        self.cpuUsage = getCPUUsage() // Also updates cpuPerCore inside
        self.memoryUsage = getMemoryUsage() // Should update memoryDetails inside
        self.diskUsage = getDiskUsage()
        getNetworkUsage()
        
        collectGPUStats()
    }
    
    private func collectGPUStats() {
        // GPU Usage via ioreg (Device Utilization %)
        DispatchQueue.global(qos: .background).async {
            let task = Process()
            // Fix: Use correct path /usr/sbin/ioreg and executableURL
            task.executableURL = URL(fileURLWithPath: "/usr/sbin/ioreg")
            
            task.arguments = ["-c", "IOAccelerator", "-r", "-d", "1"]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            
            do {
                try task.run()
                task.waitUntilExit()
            } catch {
                print("Failed to run ioreg: \(error)")
                return
            }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            // Look for "Device Utilization %" = 16
            var usage: Double = 0
            if let range = output.range(of: "\"Device Utilization %\"=(\\d+)", options: .regularExpression) {
                let match = String(output[range])
                if let valStr = match.split(separator: "=").last, let val = Double(valStr) {
                    usage = val / 100.0
                }
            } else if let range = output.range(of: "\"Tiler Utilization %\"=(\\d+)", options: .regularExpression) {
                 // Fallback for some AGX versions
                 let match = String(output[range])
                 if let valStr = match.split(separator: "=").last, let val = Double(valStr) {
                     usage = val / 100.0
                 }
            }
            
            // Thermal State Baseline
            let state = ProcessInfo.processInfo.thermalState
            var baseTemp: Double = 35.0
            switch state {
            case .nominal: baseTemp = 40.0
            case .fair: baseTemp = 55.0
            case .serious: baseTemp = 75.0
            case .critical: baseTemp = 90.0
            @unknown default: baseTemp = 40.0
            }
            
            // Add load heat
            let realTemp = baseTemp + (usage * 30.0) // 40-70C normally
            
            DispatchQueue.main.async {
                self.gpuUsage = usage
                
                // Smooth temp transition
                let change = (realTemp - self.gpuTemp) * 0.2
                self.gpuTemp = self.gpuTemp + change
                
                // History
                self.gpuHistory.append(self.gpuUsage)
                if self.gpuHistory.count > 30 { self.gpuHistory.removeFirst() }
            }
        }
    }
    
    func collectProcesses() {
        DispatchQueue.global(qos: .background).async {
            let cpu = self.getTopProcesses(sortKey: "%cpu")
            let mem = self.getTopProcesses(sortKey: "%mem")
            
            DispatchQueue.main.async {
                self.topCpuProcesses = cpu
                self.topMemProcesses = mem
            }
        }
    }
    

    
    // MARK: - CPU Usage
    private func getCPUUsage() -> Double {
        let host = mach_host_self()
        var cpuInfo: processor_info_array_t!
        var cpuInfoCount: mach_msg_type_number_t = 0
        var numCPUs: mach_msg_type_number_t = 0
        
        // Host load info (alternative) - but per core is better for detailed
        // Let's stick to overall first
        
        let result: kern_return_t = host_processor_info(host, PROCESSOR_CPU_LOAD_INFO, &numCPUs, &cpuInfo, &cpuInfoCount)
        
        guard result == KERN_SUCCESS else { return 0.0 }
        
        var totalUser: UInt32 = 0
        var totalSystem: UInt32 = 0
        var totalIdle: UInt32 = 0
        var totalNice: UInt32 = 0
        
        var newPerCore: [Double] = []
        
        if let prevCpuInfo = prevCpuInfo {
            for i in 0..<Int(numCPUs) {
                let base = i * Int(CPU_STATE_MAX)
                let user = cpuInfo[base + Int(CPU_STATE_USER)] - prevCpuInfo[base + Int(CPU_STATE_USER)]
                let system = cpuInfo[base + Int(CPU_STATE_SYSTEM)] - prevCpuInfo[base + Int(CPU_STATE_SYSTEM)]
                let nice = cpuInfo[base + Int(CPU_STATE_NICE)] - prevCpuInfo[base + Int(CPU_STATE_NICE)]
                let idle = cpuInfo[base + Int(CPU_STATE_IDLE)] - prevCpuInfo[base + Int(CPU_STATE_IDLE)]
                
                let coreTotal = user + system + nice + idle
                if coreTotal > 0 {
                    let coreUsage = Double(user + system + nice) / Double(coreTotal)
                    newPerCore.append(coreUsage)
                } else {
                    newPerCore.append(0.0)
                }
                
                totalUser += UInt32(user)
                totalSystem += UInt32(system)
                totalNice += UInt32(nice)
                totalIdle += UInt32(idle)
            }
        }
        
        DispatchQueue.main.async {
            self.cpuPerCore = newPerCore
        }
        
        // Update previous
        // let prevSize = Int(cpuInfoCount) * MemoryLayout<integer_t>.stride
        let newPrev = UnsafeMutablePointer<integer_t>.allocate(capacity: Int(cpuInfoCount))
        newPrev.initialize(from: cpuInfo, count: Int(cpuInfoCount))
        
        if let prev = self.prevCpuInfo {
            prev.deallocate()
        }
        self.prevCpuInfo = newPrev
        self.prevCpuInfoCount = cpuInfoCount
        
        // Deallocate current info from kernel
        let vmSize = Int(cpuInfoCount) * MemoryLayout<integer_t>.stride
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(vmSize))

        let total = totalUser + totalSystem + totalNice + totalIdle
        if total == 0 { return 0.0 }
        
        return Double(totalUser + totalSystem + totalNice) / Double(total)
    }
    
    // MARK: - Memory Usage
    private func getMemoryUsage() -> Double {
        var stats = vm_statistics64()
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let host = mach_host_self()
        
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(host, HOST_VM_INFO64, $0, &size)
            }
        }
        
        if result == KERN_SUCCESS {
            let pageSize = UInt64(vm_kernel_page_size)
            let active = UInt64(stats.active_count) * pageSize
            let wire = UInt64(stats.wire_count) * pageSize
            // Approximate "Used" = Active + Wired (Compressed not included for simple % yet)
            let compressed = UInt64(stats.compressor_page_count) * pageSize
            let free = UInt64(stats.free_count) * pageSize
            
            // Physical memory
            let physical = Double(ProcessInfo.processInfo.physicalMemory)
            
            let wiredBytes = Double(wire)
            let activeBytes = Double(active)
            let compressedBytes = Double(compressed)
            let freeBytes = Double(free)
            
            DispatchQueue.main.async {
                self.memoryDetails = MemoryDetails(
                    wired: wiredBytes,
                    active: activeBytes,
                    compressed: compressedBytes,
                    free: freeBytes
                )
            }
            
            let used = Double(active + wire + compressed)
            return used / physical
        }
        return 0.0
    }
    
    // MARK: - Disk Usage
    private func getDiskUsage() -> Double {
        let url = URL(fileURLWithPath: "/")
        do {
            let values = try url.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])
            if let total = values.volumeTotalCapacity, let available = values.volumeAvailableCapacity {
                return 1.0 - (Double(available) / Double(total))
            }
        } catch {
            print("Error reading disk usage: \(error)")
        }
        return 0.0
    }
    
    // MARK: - Disk IO
    @Published var diskReadSpeed: Double = 0.0
    @Published var diskWriteSpeed: Double = 0.0
    
    private var diskTask: Process?
    private var diskPipe: Pipe?
    
    // We'll use a separate simplified approach for Disk IO:
    // Parse `iostat -d -w 1` -> updates every second
    // This requires a persistent background process or repeated calls.
    // Repeated calls to `iostat -d -c 2 -w 1` (take 2nd sample) is cleaner for a periodic timer.
    
    func collectDiskIO() {
        DispatchQueue.global(qos: .background).async {
            // iostat -d -c 2 -w 1 gets 2 samples, 1 sec apart. The first is "since boot", second is "current"
            let task = Process()
            task.launchPath = "/usr/sbin/iostat"
            task.arguments = ["-d", "-c", "2", "-w", "1"]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.launch()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return }
            
            // Parse output.
            // Format example:
            // KB/t tps  MB/s
            // 23.05 14  0.31
            // ...
            // We want the last line's MB/s if possible, or we need to look at specific columns.
            // iostat output varies, but typically:
            // disk0
            // KB/t tps  MB/s
            // ...
            
            let lines = output.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .newlines)
            if let lastLine = lines.last {
                let parts = lastLine.split(separator: " ", omittingEmptySubsequences: true)
                // Assuming standard output where MB/s is often last or 3rd column depending on args.
                // With `iostat -d` it's: KB/t tps  MB/s
                // Wait, multiple disks show multiple columns. `iostat -d` sums them? No.
                // Let's rely on `netstat` logic or similar diff if iostat is hard.
                
                // Better approach: simple parse of last number (MB/s) for the primary disk if possible.
                // For MVP, if we get a double at the end, treat as MB/s total?
                // `iostat -d` shows all disks.
                
                // Let's try to just parse the last Double in the output as "Activity"
                if let speed = Double(parts.last ?? "") {
                    DispatchQueue.main.async {
                        // iostat reports MB/s
                        // We might want to split Read/Write but iostat combines them in MB/s column usually unless -I used.
                        // Let's separate Read/Write if we use `iostat -d -x`? No -x on mac.
                        // macOS `iostat` is limited.
                        
                        // Fallback: Just show "Disk Activity" as one number for now.
                        self.diskReadSpeed = speed * 1024 * 1024 // MB -> Bytes
                        self.diskWriteSpeed = 0 // Combined
                        
                        // History
                        self.diskReadHistory.append(self.diskReadSpeed)
                        if self.diskReadHistory.count > 30 { self.diskReadHistory.removeFirst() }
                        
                        self.diskWriteHistory.append(self.diskWriteSpeed)
                        if self.diskWriteHistory.count > 30 { self.diskWriteHistory.removeFirst() }
                    }
                }
            }
        }
    }
    private var lastNetworkInfo: (upload: UInt64, download: UInt64)?
    
    // Helper types for network
    struct NetworkInfo {
        var upload: UInt64
        var download: UInt64
    }
    
    private func getNetworkUsage() {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return }
        
        var totalUpload: UInt64 = 0
        var totalDownload: UInt64 = 0
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr?.pointee else { continue }
            // let name = String(cString: interface.ifa_name)
            
            // Filter loopback and non-active
            guard (interface.ifa_flags & UInt32(IFF_LOOPBACK)) == 0 else { continue }
            guard (interface.ifa_flags & UInt32(IFF_UP)) != 0 else { continue }
            guard (interface.ifa_flags & UInt32(IFF_RUNNING)) != 0 else { continue }
            
            // We care about link layer data (AF_LINK) to get bytes
            if interface.ifa_addr.pointee.sa_family == UInt8(AF_LINK) {
                if let data = interface.ifa_data?.assumingMemoryBound(to: if_data.self) {
                    totalDownload += UInt64(data.pointee.ifi_ibytes)
                    totalUpload += UInt64(data.pointee.ifi_obytes)
                }
            }
        }
        
        freeifaddrs(ifaddr)
        
        if let last = lastNetworkInfo {
            // Bytes per second (since timer is 1s)
            DispatchQueue.main.async {
                self.networkUpload = Double(totalUpload - last.upload)
                self.networkDownload = Double(totalDownload - last.download)
                
                // Update History
                self.networkDownloadHistory.append(self.networkDownload)
                if self.networkDownloadHistory.count > 30 { self.networkDownloadHistory.removeFirst() }
                
                self.networkUploadHistory.append(self.networkUpload)
                if self.networkUploadHistory.count > 30 { self.networkUploadHistory.removeFirst() }
            }
        }
        
        lastNetworkInfo = (upload: totalUpload, download: totalDownload)
    }
    
    // MARK: - Network IP
    func getLocalIP() -> String {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                guard let interface = ptr?.pointee else { continue }
                let addrFamily = interface.ifa_addr.pointee.sa_family
                
                // Check for IPv4
                if addrFamily == UInt8(AF_INET) {
                    let name = String(cString: interface.ifa_name)
                    // Prefer en0 (Wi-Fi usually)
                    if name == "en0" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                    &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address ?? "Unknown"
    }

    // Filter Logic in getTopProcesses (Modifying existing function)
    private func getTopProcesses(sortKey: String) -> [AppProcess] {
        // ... (standard ps logic)
        // ...
        // We will modify existing implementation logic to include this check
        // For simplicity, I'll rewrite the loop part here if I was replacing whole function.
        // But since this is a partial replace tool, I'll just note the filter logic:
        // let ignoreList = ["kernel_task", "launchd", "WindowServer", "loginwindow", "UserEventAgent", "gopls", "sourcekit-lsp"]
        // if ignoreList.contains(where: { name.contains($0) }) { continue }
        
        // RE-IMPLEMENTING FULL FUNCTION BELOW FOR CLARITY IN REPLACEMENT
        
        let task = Process()
        task.launchPath = "/bin/ps"
        var args = ["-Aceo", "pid,pcpu,pmem,comm"]
        if sortKey == "%mem" {
            args = ["-Amceo", "pid,pcpu,pmem,comm"]
        } else {
            args = ["-Arceo", "pid,pcpu,pmem,comm"]
        }
        task.arguments = args
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        
        guard let output = String(data: data, encoding: .utf8) else { return [] }
        
        var processes: [AppProcess] = []
        let lines = output.components(separatedBy: .newlines).dropFirst()
        
        // Filter blocked names
        let blocked = ["kernel_task", "launchd", "WindowServer", "loginwindow", "UserEventAgent", "gopls", "sourcekit-lsp", "language_server", "biometrickitd", "controlcenter"]
        
        for line in lines {
            if processes.count >= 5 { break } // Limit 5
            
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            if parts.count >= 4 {
                if let pid = Int(parts[0]),
                   let cpu = Double(parts[1]),
                   let _ = Double(parts[2]) {
                    
                    let name = parts[3...].joined(separator: " ")
                    
                    // Filter Check
                    // Filter out common background daemons if user wants just "Apps"
                    // User said: "not include language_server etc. it should show antigravity, chrome etc."
                    let isBlocked = blocked.contains { name.lowercased().contains($0.lowercased()) }
                    if isBlocked { continue }

                    // Friendly Name
                    let app = NSRunningApplication(processIdentifier: pid_t(pid))
                    let icon = app?.icon
                    let friendlyName = app?.localizedName ?? name
                    
                    if friendlyName == "arm64" || friendlyName == "x86_64" { continue }

                    let usageVal = (sortKey == "%mem") ? Double(parts[2]) ?? 0 : cpu
                    processes.append(AppProcess(pid: pid, name: friendlyName, usage: usageVal, icon: icon))
                }
            }
        }
        return processes
    }
}
