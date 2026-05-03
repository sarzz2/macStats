import SwiftUI

struct DiskView: View {
    @ObservedObject var stats: StatsCollector

    func formatBytes(_ bytes: Double) -> String {
        let b = Int64(bytes)
        return Formatters.bytes.string(fromByteCount: b)
    }

    func formatBytesLarge(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useTB]
        formatter.countStyle = .decimal
        return formatter.string(fromByteCount: bytes)
    }

    var diskColor: Color {
        if stats.diskUsage < 0.6 { return Color(hue: 0.77, saturation: 0.8, brightness: 0.85) }
        if stats.diskUsage < 0.85 { return Color(hue: 0.08, saturation: 0.95, brightness: 0.95) }
        return Color(hue: 0.0, saturation: 0.9, brightness: 0.9)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("Disk", systemImage: "internaldrive")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text(String(format: "%.1f%% used", stats.diskUsage * 100))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(diskColor)
            }
            .padding(.bottom, 10)

            // Storage ring + details
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(diskColor.opacity(0.12), lineWidth: 9)
                        .frame(width: 72, height: 72)
                    Circle()
                        .trim(from: 0, to: CGFloat(stats.diskUsage))
                        .stroke(diskColor, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                        .frame(width: 72, height: 72)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: stats.diskUsage)
                        .shadow(color: diskColor.opacity(0.4), radius: 4)
                    VStack(spacing: 0) {
                        Text(String(format: "%.0f", stats.diskUsage * 100))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text("%")
                            .font(.system(size: 9)).foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    StatRow(label: "Used",
                            value: stats.diskTotal > 0 ? formatBytesLarge(stats.diskUsed) : "--",
                            accent: diskColor)
                    StatRow(label: "Total",
                            value: stats.diskTotal > 0 ? formatBytesLarge(stats.diskTotal) : "--",
                            accent: .secondary)
                    StatRow(label: "Free",
                            value: stats.diskTotal > 0 ? formatBytesLarge(stats.diskTotal - stats.diskUsed) : "--",
                            accent: Color(hue: 0.38, saturation: 0.8, brightness: 0.75))
                }
            }
            .padding(.bottom, 10)

            AdaptiveProgressBar(value: stats.diskUsage, color: diskColor)
                .frame(height: 7)
                .padding(.bottom, 12)

            Divider().opacity(0.4).padding(.bottom, 10)

            // Read / Write speed cards
            SectionHeader(title: "I/O Speed")
            HStack(spacing: 10) {
                NetworkStatCard(
                    icon: "arrow.down.to.line.circle.fill",
                    label: "Read",
                    value: "\(formatBytes(stats.diskReadSpeed))/s",
                    color: Color(hue: 0.38, saturation: 0.8, brightness: 0.75)
                )
                NetworkStatCard(
                    icon: "arrow.up.to.line.circle.fill",
                    label: "Write",
                    value: "\(formatBytes(stats.diskWriteSpeed))/s",
                    color: Color(hue: 0.0, saturation: 0.85, brightness: 0.9)
                )
            }
            .padding(.top, 6)
            .padding(.bottom, 12)

            Divider().opacity(0.4).padding(.bottom, 10)

            // Disk I/O History
            SectionHeader(title: "I/O History (2 min)")
            DualLineGraph(
                primaryData: stats.diskReadHistory,
                secondaryData: stats.diskWriteHistory,
                primaryColor: Color(hue: 0.38, saturation: 0.8, brightness: 0.75),
                secondaryColor: Color(hue: 0.0, saturation: 0.85, brightness: 0.9),
                primaryLabel: "Read",
                secondaryLabel: "Write",
                formatValue: { Formatters.bytes.string(fromByteCount: Int64($0)) + "/s" }
            )
            .frame(height: 80)
            .padding(.top, 4)
        }
        .padding(14)
        .frame(width: 320)
    }
}
