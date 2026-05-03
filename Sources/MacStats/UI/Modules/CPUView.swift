import SwiftUI

struct CPUView: View {
    @ObservedObject var stats: StatsCollector

    let columns = [GridItem(.flexible()), GridItem(.flexible()),
                   GridItem(.flexible()), GridItem(.flexible())]

    var cpuColor: Color {
        if stats.cpuUsage < 0.4 { return Color(hue: 0.38, saturation: 0.8, brightness: 0.75) }
        if stats.cpuUsage < 0.7 { return Color(hue: 0.55, saturation: 0.85, brightness: 0.9) }
        if stats.cpuUsage < 0.9 { return Color(hue: 0.08, saturation: 0.95, brightness: 0.95) }
        return Color(hue: 0.0, saturation: 0.9, brightness: 0.9)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("CPU", systemImage: "cpu")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                StatusBadge(text: stats.cpuFrequencyMode, color: cpuColor)
            }
            .padding(.bottom, 10)

            // Usage gauge ring + percentage
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(cpuColor.opacity(0.12), lineWidth: 9)
                        .frame(width: 72, height: 72)

                    Circle()
                        .trim(from: 0, to: CGFloat(stats.cpuUsage))
                        .stroke(cpuColor, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                        .frame(width: 72, height: 72)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: stats.cpuUsage)
                        .shadow(color: cpuColor.opacity(0.4), radius: 4)

                    VStack(spacing: 0) {
                        Text(String(format: "%.0f", stats.cpuUsage * 100))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text("%")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    StatRow(label: "User", value: String(format: "%.1f%%", stats.cpuUsage * 100), accent: cpuColor)
                    StatRow(label: "Mode", value: stats.cpuFrequencyMode, accent: cpuColor)
                    StatRow(label: "Uptime", value: stats.systemUptime, accent: .cyan)
                    StatRow(label: "Cores", value: "\(stats.cpuPerCore.count)", accent: .secondary)
                }
            }
            .padding(.bottom, 10)

            // Progress bar
            AdaptiveProgressBar(value: stats.cpuUsage)
                .frame(height: 7)
                .padding(.bottom, 12)

            Divider().opacity(0.4).padding(.bottom, 10)

            // Per-Core Grid
            SectionHeader(title: "Per Core")
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<stats.cpuPerCore.count, id: \.self) { i in
                    let usage = stats.cpuPerCore[i]
                    CoreBar(index: i, usage: usage)
                }
            }
            .padding(.top, 6)
            .padding(.bottom, 12)

            Divider().opacity(0.4).padding(.bottom, 10)

            // History Graph
            SectionHeader(title: "History (2 min)")
            SmoothLineGraph(
                data: stats.cpuHistory,
                color: cpuColor,
                formatValue: { String(format: "%.1f%%", $0 * 100) }
            )
            .frame(height: 70)
            .padding(.top, 4)
            .padding(.bottom, 12)

            Divider().opacity(0.4).padding(.bottom, 10)

            // Top Processes
            SectionHeader(title: "Top Processes")
            VStack(spacing: 6) {
                ForEach(stats.topCpuProcesses) { process in
                    ProcessRow(process: process, accent: cpuColor, suffix: "%")
                }
            }
            .padding(.top, 4)
        }
        .padding(14)
        .frame(width: 320)
    }
}

struct CoreBar: View {
    let index: Int
    let usage: Double
    @State private var hovered = false

    var coreColor: Color {
        if usage < 0.4 { return Color(hue: 0.38, saturation: 0.8, brightness: 0.75) }
        if usage < 0.7 { return Color(hue: 0.55, saturation: 0.85, brightness: 0.9) }
        if usage < 0.9 { return Color(hue: 0.08, saturation: 0.95, brightness: 0.95) }
        return Color(hue: 0.0, saturation: 0.9, brightness: 0.9)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("C\(index + 1)")
                .font(.system(size: 7, weight: .medium))
                .foregroundColor(.secondary)

            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(coreColor.opacity(0.12))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [coreColor.opacity(0.6), coreColor]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: max(3, geo.size.height * CGFloat(usage)))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: usage)
                }
            }
            .frame(height: 32)
            .scaleEffect(hovered ? 1.08 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: hovered)

            Text("\(Int(usage * 100))%")
                .font(.system(size: 7))
                .foregroundColor(hovered ? coreColor : .secondary)
                .animation(.easeInOut(duration: 0.1), value: hovered)
        }
        .onHover { hovered = $0 }
    }
}

struct ProcessRow: View {
    let process: StatsCollector.AppProcess
    let accent: Color
    let suffix: String
    @State private var hovered = false

    var body: some View {
        HStack(spacing: 8) {
            if let icon = process.icon {
                Image(nsImage: icon).resizable().frame(width: 16, height: 16).cornerRadius(3)
            } else {
                Image(systemName: "gear").resizable().frame(width: 14, height: 14).foregroundColor(.secondary)
            }

            Text(process.name)
                .font(.caption)
                .lineLimit(1)
                .foregroundColor(hovered ? .primary : .secondary)

            Spacer()

            Text(String(format: "%.1f\(suffix)", process.usage))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(hovered ? accent : .primary)
                .monospacedDigit()
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(hovered ? accent.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .animation(.easeInOut(duration: 0.12), value: hovered)
        .onHover { hovered = $0 }
    }
}

// Kept for any backward compatibility
struct MainBar: View {
    var value: Double
    var color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                Rectangle().frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.1).foregroundColor(color)
                Rectangle().frame(width: geometry.size.width, height: min(CGFloat(self.value)*geometry.size.height, geometry.size.height))
                    .foregroundColor(color)
            }
            .cornerRadius(4)
        }
    }
}
