import SwiftUI

struct SensorsView: View {
    @ObservedObject var sensors: SensorCollector
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Sensors")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Thermal Pressure: \(sensors.thermalPressure)")
                    .bold()
                
                Divider()
                
                ForEach(sensors.sensors) { sensor in
                    VStack(spacing: 2) {
                        HStack {
                            Text(sensor.name)
                                .font(.caption)
                            Spacer()
                            Text(String(format: "%.0f%@", sensor.value, sensor.unit))
                                .font(.caption)
                                .bold()
                        }
                        
                        // Bar (assuming range 0-100 for temperature)
                        GeometryReader { g in
                            let w = g.size.width
                            let pct = min(max(sensor.value / 100.0, 0), 1)
                            
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.gray.opacity(0.2))
                                Capsule().fill(pct > 0.8 ? Color.red : (pct > 0.6 ? Color.orange : Color.blue))
                                    .frame(width: w * CGFloat(pct))
                            }
                        }
                        .frame(height: 4)
                    }
                }
                
                if sensors.sensors.isEmpty {
                    Text("No sensors detected (Apple Silicon restriction)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(width: 300)
    }
}
