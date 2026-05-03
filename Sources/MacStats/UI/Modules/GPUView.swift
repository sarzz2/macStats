import SwiftUI

struct GPUView: View {
    @ObservedObject var stats: StatsCollector

    var gpuColor: Color {
        if stats.gpuUsage < 0.4 { return Color(hue: 0.85, saturation: 0.8, brightness: 0.9) }  // pink-purple
        if stats.gpuUsage < 0.7 { return Color(hue: 0.77, saturation: 0.85, brightness: 0.9) }  // purple
        if stats.gpuUsage < 0.9 { return Color(hue: 0.08, saturation: 0.95, brightness: 0.95) } // amber
        return Color(hue: 0.0, saturation: 0.9, brightness: 0.9)
    }

    var tempColor: Color {
        if stats.gpuTemp < 50 { return Color(hue: 0.38, saturation: 0.8, brightness: 0.75) }
        if stats.gpuTemp < 70 { return Color(hue: 0.08, saturation: 0.95, brightness: 0.95) }
        return Color(hue: 0.0, saturation: 0.9, brightness: 0.9)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("GPU", systemImage: "cpu.fill")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                StatusBadge(
                    text: stats.gpuUsage > 0 ? "Active" : "Idle",
                    color: stats.gpuUsage > 0 ? gpuColor : .secondary
                )
            }
            .padding(.bottom, 10)

            // Gauge ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(gpuColor.opacity(0.1), lineWidth: 14)
                    .frame(width: 110, height: 110)

                // Outer glow ring (usage)
                Circle()
                    .trim(from: 0, to: CGFloat(stats.gpuUsage))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [gpuColor.opacity(0.7), gpuColor]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(-90 + 360 * stats.gpuUsage)
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.75), value: stats.gpuUsage)
                    .shadow(color: gpuColor.opacity(0.5), radius: 6)

                VStack(spacing: 2) {
                    Text(String(format: "%.0f%%", stats.gpuUsage * 100))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text("GPU Load")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 10)

            // Stats row
            HStack(spacing: 0) {
                GPUStatCell(icon: "thermometer", label: "Temp",
                            value: String(format: "%.0f°C", stats.gpuTemp),
                            color: tempColor)

                Divider().frame(height: 36)

                GPUStatCell(icon: "memorychip", label: "Memory",
                            value: "Dynamic",
                            color: Color(hue: 0.55, saturation: 0.85, brightness: 0.9))

                Divider().frame(height: 36)

                GPUStatCell(icon: "bolt.fill", label: "Mode",
                            value: stats.cpuFrequencyMode,
                            color: Color(hue: 0.12, saturation: 0.9, brightness: 0.95))
            }
            .padding(.bottom, 12)

            Divider().opacity(0.4).padding(.bottom, 10)

            // GPU History
            SectionHeader(title: "History (2 min)")
            SmoothLineGraph(
                data: stats.gpuHistory,
                color: gpuColor,
                formatValue: { String(format: "%.1f%%", $0 * 100) }
            )
            .frame(height: 70)
            .padding(.top, 4)
        }
        .padding(14)
        .frame(width: 300)
    }
}

struct GPUStatCell: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    @State private var hovered = false

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(hovered ? color : .secondary)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(hovered ? color : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .animation(.easeInOut(duration: 0.12), value: hovered)
        .onHover { hovered = $0 }
    }
}
