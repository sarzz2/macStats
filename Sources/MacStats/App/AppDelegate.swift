import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var modules: [ModuleController] = []
    
    // Shared collectors
    let statsCollector = StatsCollector()
    let sensorCollector = SensorCollector()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // CPU Module
        let cpuModule = ModuleController(
            title: "CPU",
            iconName: "cpu",
            view: AnyView(CPUView(stats: statsCollector)),
            updateClosure: { [weak self] button in
                guard let self = self else { return }
                button.title = String(format: "%.0f%%", self.statsCollector.cpuUsage * 100)
            }
        )
        
        // Memory Module
        let memModule = ModuleController(
            title: "MEM",
            iconName: "memorychip",
            view: AnyView(MemoryView(stats: statsCollector)),
            updateClosure: { [weak self] button in
                guard let self = self else { return }
                button.title = String(format: "%.0f%%", self.statsCollector.memoryUsage * 100)
            }
        )
        
        // Disk Module
        let diskModule = ModuleController(
            title: "DSK",
            iconName: "internaldrive",
            view: AnyView(DiskView(stats: statsCollector)),
            updateClosure: { [weak self] button in
                guard let self = self else { return }
                button.title = String(format: "%.0f%%", self.statsCollector.diskUsage * 100)
            }
        )
        
        // Network Module
        let netModule = ModuleController(
            title: "NET",
            iconName: "network",
            view: AnyView(NetworkView(stats: statsCollector)),
            width: 60, // Increased width further for larger values
            updateClosure: { [weak self] button in
                guard let self = self else { return }
                let down = self.formatBytesShort(self.statsCollector.networkDownload)
                let up = self.formatBytesShort(self.statsCollector.networkUpload)
                
                // Stacked Text using Attributed String
                // Stacked Text using Attributed String
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center // Center text
                paragraphStyle.maximumLineHeight = 9 
                paragraphStyle.lineSpacing = 0
                
                let text = "⬇ \(down)\n⬆ \(up)"
                let attrStr = NSAttributedString(string: text, attributes: [
                    .font: NSFont.systemFont(ofSize: 9, weight: .medium),
                    .paragraphStyle: paragraphStyle,
                    .foregroundColor: NSColor.labelColor
                ])
                
                button.attributedTitle = attrStr
            }
        )
        
        // Sensors Module (Temp)
        let sensorModule = ModuleController(
            title: "TMP",
            iconName: "thermometer",
            view: AnyView(SensorsView(sensors: sensorCollector)),
            updateClosure: { [weak self] button in
                guard let self = self else { return }
                if let cpuTemp = self.sensorCollector.sensors.first(where: { $0.name.contains("CPU") }) {
                    button.title = String(format: "%.0f°", cpuTemp.value)
                } else {
                    button.title = self.sensorCollector.thermalPressure
                }
            }
        )
        
        // GPU Module
        let gpuModule = ModuleController(
            title: "GPU",
            iconName: "cpu.fill",
            view: AnyView(GPUView(stats: statsCollector)),
            updateClosure: { [weak self] button in
                guard let self = self else { return }
                button.title = String(format: "%.0f%%", self.statsCollector.gpuUsage * 100)
            }
        )
        
        modules = [cpuModule, memModule, diskModule, netModule, gpuModule, sensorModule]
    }
    
    func formatBytesShort(_ bytes: Double) -> String {
        if bytes == 0 { return "0" }
        let b = Int64(bytes)
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useGB]
        formatter.countStyle = .memory
        formatter.includesUnit = true
        return formatter.string(fromByteCount: b)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "MB", with: "M")
            .replacingOccurrences(of: "KB", with: "K")
            .replacingOccurrences(of: "GB", with: "G")
            .replacingOccurrences(of: "bytes", with: "B")
    }
}
