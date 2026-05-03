import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var modules: [ModuleController] = []

    // Shared collectors — one instance each, referenced by all views
    let statsCollector = StatsCollector()
    let sensorCollector = SensorCollector()

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        // CPU Module
        let cpuModule = ModuleController(
            title: "CPU",
            iconName: "cpu",
            view: AnyView(CPUView(stats: statsCollector)),
            popoverHeight: 460,
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
            popoverHeight: 520,
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
            popoverHeight: 440,
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
            popoverHeight: 360,
            width: 60,
            updateClosure: { [weak self] button in
                guard let self = self else { return }
                let down = self.formatBytesShort(self.statsCollector.networkDownload)
                let up   = self.formatBytesShort(self.statsCollector.networkUpload)

                let style = NSMutableParagraphStyle()
                style.alignment = .center
                style.maximumLineHeight = 9
                style.lineSpacing = 0

                let attrStr = NSAttributedString(
                    string: "⬇ \(down)\n⬆ \(up)",
                    attributes: [
                        .font: NSFont.systemFont(ofSize: 9, weight: .medium),
                        .paragraphStyle: style,
                        .foregroundColor: NSColor.labelColor
                    ]
                )
                button.attributedTitle = attrStr
            }
        )

        // GPU Module
        let gpuModule = ModuleController(
            title: "GPU",
            iconName: "cpu.fill",
            view: AnyView(GPUView(stats: statsCollector)),
            popoverHeight: 380,
            updateClosure: { [weak self] button in
                guard let self = self else { return }
                button.title = String(format: "%.0f%%", self.statsCollector.gpuUsage * 100)
            }
        )

        // Battery Module
        let batteryModule = ModuleController(
            title: "BAT",
            iconName: "battery.75",
            view: AnyView(BatteryView(stats: statsCollector)),
            popoverHeight: 360,
            updateClosure: { [weak self] button in
                guard let self = self else { return }
                let pct = Int(self.statsCollector.batteryLevel * 100)
                let bolt = self.statsCollector.batteryCharging ? "⚡" : ""
                button.title = "\(bolt)\(pct)%"
            }
        )

        // Sensors Module
        let sensorModule = ModuleController(
            title: "TMP",
            iconName: "thermometer",
            view: AnyView(SensorsView(sensors: sensorCollector)),
            popoverHeight: 520,
            updateClosure: { [weak self] button in
                guard let self = self else { return }
                if let cpuSensor = self.sensorCollector.sensors.first(where: { $0.name.lowercased().contains("cpu") }) {
                    button.title = String(format: "%.0f°", cpuSensor.value)
                } else {
                    button.title = self.sensorCollector.thermalPressure
                }
            }
        )

        modules = [cpuModule, memModule, diskModule, netModule, gpuModule, batteryModule, sensorModule]
    }

    func formatBytesShort(_ bytes: Double) -> String {
        if bytes == 0 { return "0" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useGB]
        formatter.countStyle = .memory
        formatter.includesUnit = true
        return formatter.string(fromByteCount: Int64(bytes))
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "MB", with: "M")
            .replacingOccurrences(of: "KB", with: "K")
            .replacingOccurrences(of: "GB", with: "G")
            .replacingOccurrences(of: "bytes", with: "B")
    }
}
