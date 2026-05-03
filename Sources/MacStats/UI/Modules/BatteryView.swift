import SwiftUI

struct BatteryView: View {
    @ObservedObject var stats: StatsCollector

    var batteryColor: Color {
        if stats.batteryCharging { return Color(hue: 0.38, saturation: 0.85, brightness: 0.8) }
        if stats.batteryLevel > 0.4 { return Color(hue: 0.38, saturation: 0.8, brightness: 0.75) }
        if stats.batteryLevel > 0.2 { return Color(hue: 0.08, saturation: 0.95, brightness: 0.95) }
        return Color(hue: 0.0, saturation: 0.9, brightness: 0.9)
    }

    var batteryIconName: String {
        if stats.batteryCharging { return "battery.100.bolt" }
        let pct = Int(stats.batteryLevel * 100)
        switch pct {
        case 76...: return "battery.100"
        case 51...: return "battery.75"
        case 26...: return "battery.50"
        case 11...: return "battery.25"
        default: return "battery.0"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("Battery", systemImage: batteryIconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(batteryColor)
                Spacer()
                StatusBadge(
                    text: stats.batteryCharging ? "Charging" : "On Battery",
                    color: batteryColor
                )
            }
            .padding(.bottom, 12)

            // Ring gauge
            ZStack {
                Circle()
                    .stroke(batteryColor.opacity(0.12), lineWidth: 14)
                    .frame(width: 110, height: 110)

                Circle()
                    .trim(from: 0, to: CGFloat(stats.batteryLevel))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [batteryColor.opacity(0.7), batteryColor]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(-90 + 360 * stats.batteryLevel)
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: stats.batteryLevel)
                    .shadow(color: batteryColor.opacity(0.5), radius: 5)

                VStack(spacing: 2) {
                    Text(String(format: "%.0f%%", stats.batteryLevel * 100))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text(stats.batteryCharging ? "Charging" : "Battery")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 10)

            // Details
            VStack(spacing: 6) {
                StatRow(label: "Status", value: stats.batteryCharging ? "Charging" : "Discharging", accent: batteryColor)
                StatRow(label: "Time Remaining", value: stats.batteryTimeRemaining, accent: .cyan)
                StatRow(label: "Uptime", value: stats.systemUptime, accent: .secondary)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 12)

            // Battery bar
            AdaptiveProgressBar(value: stats.batteryLevel, color: batteryColor)
                .frame(height: 8)
                .padding(.bottom, 12)

            Divider().opacity(0.4).padding(.bottom, 10)

            // Thermal state
            HStack {
                SectionHeader(title: "Thermal State")
                Spacer()
                StatusBadge(text: stats.cpuFrequencyMode, color: thermalColor)
            }
            .padding(.bottom, 4)

            HStack {
                Image(systemName: "thermometer.medium")
                    .font(.system(size: 28))
                    .foregroundColor(thermalColor)
                    .shadow(color: thermalColor.opacity(0.4), radius: 4)
                VStack(alignment: .leading, spacing: 2) {
                    Text(stats.cpuFrequencyMode)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(thermalColor)
                    Text("System thermal pressure")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(thermalColor.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 9))
        }
        .padding(14)
        .frame(width: 300)
    }

    var thermalColor: Color {
        switch stats.cpuFrequencyMode {
        case "Performance": return Color(hue: 0.38, saturation: 0.8, brightness: 0.75)
        case "Balanced": return Color(hue: 0.55, saturation: 0.85, brightness: 0.9)
        case "Throttled": return Color(hue: 0.08, saturation: 0.95, brightness: 0.95)
        case "Critical": return Color(hue: 0.0, saturation: 0.9, brightness: 0.9)
        default: return .secondary
        }
    }
}
