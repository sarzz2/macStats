import Foundation

struct ThermalSensor: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let unit: String
}

class SensorCollector: ObservableObject {
    @Published var sensors: [ThermalSensor] = []
    
    // Simplistic text for thermal pressure
    @Published var thermalPressure: String = "Nominal"
    
    // Fan speed
    @Published var fans: [ThermalSensor] = []
    
    private var timer: Timer?
    
    init() {
        startCollecting()
    }
    
    func startCollecting() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.collectSensors()
        }
    }
    
    func collectSensors() {
        // NOTE: True sensor reading on macOS (especially Apple Silicon) requires
        // complex IOKit integration or a kernel extension, which is beyond the scope
        // of a simple Swift snippet without external dependencies like SMCKit.
        // We will simulate or provide placeholders.
        
        // In a real app, you would use IOKit to iterate IOReport or AppleCLPC.
        
        self.sensors = [
            // Simulated list based on user request for "20-30" items
            ThermalSensor(name: "CPU efficiency core 1", value: Double.random(in: 30...45), unit: "°C"),
            ThermalSensor(name: "CPU efficiency core 2", value: Double.random(in: 30...45), unit: "°C"),
            ThermalSensor(name: "CPU performance core 1", value: Double.random(in: 40...60), unit: "°C"),
            ThermalSensor(name: "CPU performance core 2", value: Double.random(in: 40...60), unit: "°C"),
            ThermalSensor(name: "CPU performance core 3", value: Double.random(in: 40...60), unit: "°C"),
            ThermalSensor(name: "CPU performance core 4", value: Double.random(in: 40...60), unit: "°C"),
            ThermalSensor(name: "GPU Cluster 1", value: Double.random(in: 35...55), unit: "°C"),
            ThermalSensor(name: "GPU Cluster 2", value: Double.random(in: 35...55), unit: "°C"),
            ThermalSensor(name: "ANE (Neural Engine)", value: Double.random(in: 30...40), unit: "°C"),
            ThermalSensor(name: "ISP", value: Double.random(in: 30...40), unit: "°C"),
            ThermalSensor(name: "Battery 1", value: Double.random(in: 25...35), unit: "°C"),
            ThermalSensor(name: "Battery 2", value: Double.random(in: 25...35), unit: "°C"),
            ThermalSensor(name: "DC In", value: Double.random(in: 30...50), unit: "°C"),
            ThermalSensor(name: "Airport/Wi-Fi", value: Double.random(in: 40...50), unit: "°C"),
            ThermalSensor(name: "Memory Bank 1", value: Double.random(in: 30...45), unit: "°C"),
            ThermalSensor(name: "Memory Bank 2", value: Double.random(in: 30...45), unit: "°C"),
            ThermalSensor(name: "Thunderbolt Left", value: Double.random(in: 30...45), unit: "°C"),
            ThermalSensor(name: "Thunderbolt Right", value: Double.random(in: 30...45), unit: "°C"),
            ThermalSensor(name: "PMU tdie1", value: Double.random(in: 40...60), unit: "°C"),
            ThermalSensor(name: "PMU tdie2", value: Double.random(in: 40...60), unit: "°C"),
            ThermalSensor(name: "NAND Storage", value: Double.random(in: 30...40), unit: "°C"),
            ThermalSensor(name: "Wireless Charger", value: Double.random(in: 25...30), unit: "°C")
        ]
        
        self.fans = [
            ThermalSensor(name: "Fan Right", value: 1200, unit: "RPM"),
            ThermalSensor(name: "Fan Left", value: 1150, unit: "RPM")
        ]
        
        // We can try to read thermal pressure from NSProcessInfo or similar if available,
        // but ProcessInfo only gives thermalState.
        let state = ProcessInfo.processInfo.thermalState
        switch state {
        case .nominal: thermalPressure = "Nominal"
        case .fair: thermalPressure = "Fair"
        case .serious: thermalPressure = "Serious"
        case .critical: thermalPressure = "Critical"
        @unknown default: thermalPressure = "Unknown"
        }
    }
}
