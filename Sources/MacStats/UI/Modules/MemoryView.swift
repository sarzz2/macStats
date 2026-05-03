import SwiftUI

struct MemoryView: View {
    @ObservedObject var stats: StatsCollector

    func formatBytes(_ bytes: Double) -> String {
        let b = Int64(bytes)
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: b)
    }

    var pressureColor: Color {
        switch stats.memoryPressure {
        case "High": return Color(hue: 0.0, saturation: 0.9, brightness: 0.9)
        case "Medium": return Color(hue: 0.08, saturation: 0.95, brightness: 0.95)
        default: return Color(hue: 0.38, saturation: 0.8, brightness: 0.75)
        }
    }

    var memColor: Color {
        if stats.memoryUsage < 0.6 { return Color(hue: 0.38, saturation: 0.8, brightness: 0.75) }
        if stats.memoryUsage < 0.8 { return Color(hue: 0.55, saturation: 0.85, brightness: 0.9) }
        return Color(hue: 0.0, saturation: 0.9, brightness: 0.9)
    }

    var totalBytes: Double { stats.memoryDetails.total }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("Memory", systemImage: "memorychip")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                StatusBadge(text: stats.memoryPressure, color: pressureColor)
            }
            .padding(.bottom, 10)

            // Usage gauge ring
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(memColor.opacity(0.12), lineWidth: 9)
                        .frame(width: 72, height: 72)

                    Circle()
                        .trim(from: 0, to: CGFloat(stats.memoryUsage))
                        .stroke(memColor, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                        .frame(width: 72, height: 72)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: stats.memoryUsage)
                        .shadow(color: memColor.opacity(0.4), radius: 4)

                    VStack(spacing: 0) {
                        Text(String(format: "%.0f", stats.memoryUsage * 100))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text("%")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    StatRow(label: "Used", value: formatBytes((stats.memoryDetails.wired + stats.memoryDetails.active + stats.memoryDetails.compressed)), accent: memColor)
                    StatRow(label: "Total", value: totalBytes > 0 ? formatBytes(totalBytes) : "--", accent: .secondary)
                    StatRow(label: "Pressure", value: stats.memoryPressure, accent: pressureColor)
                    StatRow(label: "Swap Used", value: stats.swapTotal > 0 ? formatBytes(stats.swapUsed) : "None", accent: .purple)
                }
            }
            .padding(.bottom, 10)

            AdaptiveProgressBar(value: stats.memoryUsage)
                .frame(height: 7)
                .padding(.bottom, 12)

            Divider().opacity(0.4).padding(.bottom, 10)

            // Memory breakdown
            SectionHeader(title: "Breakdown")
            VStack(spacing: 6) {
                MemSegmentRow(label: "Wired", value: stats.memoryDetails.wired, total: totalBytes, color: Color(hue: 0.08, saturation: 0.9, brightness: 0.9))
                MemSegmentRow(label: "Active", value: stats.memoryDetails.active, total: totalBytes, color: Color(hue: 0.55, saturation: 0.9, brightness: 0.9))
                MemSegmentRow(label: "Compressed", value: stats.memoryDetails.compressed, total: totalBytes, color: Color(hue: 0.77, saturation: 0.8, brightness: 0.85))
                MemSegmentRow(label: "Free", value: stats.memoryDetails.free, total: totalBytes, color: Color(hue: 0.38, saturation: 0.7, brightness: 0.75))
            }
            .padding(.top, 6)
            .padding(.bottom, 12)

            Divider().opacity(0.4).padding(.bottom, 10)

            // Swap section
            if stats.swapTotal > 0 {
                SectionHeader(title: "Swap")
                let swapFrac = stats.swapTotal > 0 ? stats.swapUsed / stats.swapTotal : 0
                HStack {
                    Text(formatBytes(stats.swapUsed))
                        .font(.caption).fontWeight(.semibold).foregroundColor(.purple)
                    Text("/ \(formatBytes(stats.swapTotal))")
                        .font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.0f%%", swapFrac * 100))
                        .font(.caption2).foregroundColor(.secondary)
                }
                .padding(.top, 4)
                AdaptiveProgressBar(value: swapFrac, color: .purple)
                    .frame(height: 5)
                    .padding(.top, 4)
                    .padding(.bottom, 12)
                Divider().opacity(0.4).padding(.bottom, 10)
            }

            // History Graph
            SectionHeader(title: "History (2 min)")
            SmoothLineGraph(
                data: stats.memHistory,
                color: memColor,
                formatValue: { String(format: "%.1f%%", $0 * 100) }
            )
            .frame(height: 60)
            .padding(.top, 4)
            .padding(.bottom, 12)

            Divider().opacity(0.4).padding(.bottom, 10)

            // Top Processes
            SectionHeader(title: "Top Processes (Memory)")
            VStack(spacing: 6) {
                ForEach(stats.topMemProcesses) { process in
                    ProcessRow(process: process, accent: memColor, suffix: "%")
                }
            }
            .padding(.top, 4)
        }
        .padding(14)
        .frame(width: 320)
    }
}

struct MemSegmentRow: View {
    let label: String
    let value: Double
    let total: Double
    let color: Color

    @State private var hovered = false

    var fraction: Double { total > 0 ? min(value / total, 1.0) : 0 }

    func formatBytes(_ bytes: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }

    var body: some View {
        VStack(spacing: 3) {
            HStack {
                Circle().fill(color).frame(width: 7, height: 7)
                Text(label).font(.caption).foregroundColor(.secondary)
                Spacer()
                Text(formatBytes(value))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(hovered ? color : .primary)
                    .monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.1))
                    Capsule()
                        .fill(LinearGradient(gradient: Gradient(colors: [color, color.opacity(0.7)]), startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(fraction))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: fraction)
                }
            }
            .frame(height: 4)
        }
        .onHover { hovered = $0 }
    }
}
