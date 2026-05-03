import SwiftUI

struct SensorsView: View {
    @ObservedObject var sensors: SensorCollector
    @State private var hoveredId: UUID? = nil

    func tempColor(_ v: Double) -> Color {
        if v < 45 { return Color(hue: 0.38, saturation: 0.8, brightness: 0.75) }
        if v < 65 { return Color(hue: 0.08, saturation: 0.95, brightness: 0.95) }
        return Color(hue: 0.0, saturation: 0.9, brightness: 0.9)
    }

    var pressureColor: Color {
        switch sensors.thermalPressure {
        case "Nominal": return Color(hue: 0.38, saturation: 0.8, brightness: 0.75)
        case "Fair": return Color(hue: 0.55, saturation: 0.85, brightness: 0.9)
        case "Serious": return Color(hue: 0.08, saturation: 0.95, brightness: 0.95)
        case "Critical": return Color(hue: 0.0, saturation: 0.9, brightness: 0.9)
        default: return .secondary
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("Sensors", systemImage: "thermometer.medium")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                StatusBadge(text: sensors.thermalPressure, color: pressureColor)
            }
            .padding(.bottom, 12)

            // Thermal pressure banner
            HStack(spacing: 10) {
                Image(systemName: "thermometer.sun.fill")
                    .font(.system(size: 22))
                    .foregroundColor(pressureColor)
                    .shadow(color: pressureColor.opacity(0.5), radius: 4)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Thermal Pressure")
                        .font(.system(size: 10)).foregroundColor(.secondary)
                    Text(sensors.thermalPressure)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(pressureColor)
                }
                Spacer()
            }
            .padding(10)
            .background(pressureColor.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .padding(.bottom, 12)

            Divider().opacity(0.4).padding(.bottom, 10)

            // Sensor list
            SectionHeader(title: "Thermal Sensors")

            if sensors.sensors.isEmpty {
                Text("No sensor data (Apple Silicon restriction)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 16)
            } else {
                VStack(spacing: 5) {
                    ForEach(sensors.sensors) { sensor in
                        SensorRow(sensor: sensor, color: tempColor(sensor.value), isHovered: hoveredId == sensor.id)
                            .onHover { hovering in hoveredId = hovering ? sensor.id : nil }
                    }
                }
                .padding(.top, 6)
            }
        }
        .padding(14)
        .frame(width: 300)
    }
}

struct SensorRow: View {
    let sensor: ThermalSensor
    let color: Color
    let isHovered: Bool

    var body: some View {
        VStack(spacing: 3) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .shadow(color: color.opacity(isHovered ? 0.6 : 0), radius: 3)

                Text(sensor.name)
                    .font(.system(size: 11))
                    .foregroundColor(isHovered ? .primary : .secondary)
                    .lineLimit(1)

                Spacer()

                Text(String(format: "%.0f%@", sensor.value, sensor.unit))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isHovered ? color : .primary)
                    .monospacedDigit()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.1))
                    Capsule()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [color.opacity(0.7), color]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * CGFloat(min(sensor.value / 100.0, 1.0)))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: sensor.value)
                }
            }
            .frame(height: isHovered ? 5 : 3)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(isHovered ? color.opacity(0.06) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .animation(.easeInOut(duration: 0.12), value: isHovered)
    }
}
