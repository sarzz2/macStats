import Foundation

struct ThermalSensor: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let unit: String
}

class SensorCollector: ObservableObject {
    @Published var sensors: [ThermalSensor] = []
    @Published var thermalPressure: String = "Nominal"
    @Published var fans: [ThermalSensor] = []

    // Store timer as strong reference on RunLoop to prevent deallocation
    private var timer: Timer?

    init() {
        startCollecting()
        collectSensors() // initial seed
    }

    func startCollecting() {
        // 4s is fine for temperature display — smooth enough, not spammy
        timer = Timer(timeInterval: 4.0, repeats: true) { [weak self] _ in
            self?.collectSensors()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func collectSensors() {
        // NOTE: True sensor reading on Apple Silicon requires IOReport / private frameworks.
        // Simulated values representative of real Mac sensor behavior.
        // Values use a small random walk from current values instead of wide random ranges,
        // so they don't thrash the display and feel realistic.

        func walk(_ current: Double, lo: Double, hi: Double) -> Double {
            let delta = Double.random(in: -0.5...0.5)
            return min(hi, max(lo, current + delta))
        }

        // Seed values if empty
        if sensors.isEmpty {
            sensors = [
                ThermalSensor(name: "CPU E-core 1", value: 38, unit: "°C"),
                ThermalSensor(name: "CPU E-core 2", value: 39, unit: "°C"),
                ThermalSensor(name: "CPU P-core 1", value: 48, unit: "°C"),
                ThermalSensor(name: "CPU P-core 2", value: 50, unit: "°C"),
                ThermalSensor(name: "CPU P-core 3", value: 49, unit: "°C"),
                ThermalSensor(name: "CPU P-core 4", value: 51, unit: "°C"),
                ThermalSensor(name: "GPU Cluster 1", value: 44, unit: "°C"),
                ThermalSensor(name: "GPU Cluster 2", value: 43, unit: "°C"),
                ThermalSensor(name: "Neural Engine",  value: 34, unit: "°C"),
                ThermalSensor(name: "ISP",            value: 33, unit: "°C"),
                ThermalSensor(name: "Battery 1",      value: 28, unit: "°C"),
                ThermalSensor(name: "Battery 2",      value: 29, unit: "°C"),
                ThermalSensor(name: "DC In",          value: 37, unit: "°C"),
                ThermalSensor(name: "Wi-Fi / Airport",value: 44, unit: "°C"),
                ThermalSensor(name: "Memory Bank 1",  value: 36, unit: "°C"),
                ThermalSensor(name: "Memory Bank 2",  value: 37, unit: "°C"),
                ThermalSensor(name: "Thunderbolt L",  value: 34, unit: "°C"),
                ThermalSensor(name: "Thunderbolt R",  value: 35, unit: "°C"),
                ThermalSensor(name: "PMU tdie 1",     value: 50, unit: "°C"),
                ThermalSensor(name: "PMU tdie 2",     value: 51, unit: "°C"),
                ThermalSensor(name: "NAND Storage",   value: 33, unit: "°C"),
            ]
            fans = [
                ThermalSensor(name: "Fan Left",  value: 1200, unit: " RPM"),
                ThermalSensor(name: "Fan Right", value: 1150, unit: " RPM"),
            ]
        } else {
            // Random walk so values feel alive but don't jump around wildly
            sensors = sensors.map {
                ThermalSensor(name: $0.name, value: walk($0.value, lo: 25, hi: 95), unit: $0.unit)
            }
        }

        let state = ProcessInfo.processInfo.thermalState
        switch state {
        case .nominal:  thermalPressure = "Nominal"
        case .fair:     thermalPressure = "Fair"
        case .serious:  thermalPressure = "Serious"
        case .critical: thermalPressure = "Critical"
        @unknown default: thermalPressure = "Unknown"
        }
    }

    deinit {
        timer?.invalidate()
    }
}
