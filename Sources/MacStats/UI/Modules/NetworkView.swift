import SwiftUI

struct NetworkView: View {
    @ObservedObject var stats: StatsCollector

    func formatBytes(_ bytes: Double) -> String {
        let b = Int64(bytes)
        return Formatters.bytes.string(fromByteCount: b)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("Network", systemImage: "network")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                StatusBadge(text: stats.getLocalIP(), color: .cyan)
            }
            .padding(.bottom, 10)

            // Download / Upload cards
            HStack(spacing: 10) {
                NetworkStatCard(
                    icon: "arrow.down.circle.fill",
                    label: "Download",
                    value: "\(formatBytes(stats.networkDownload))/s",
                    color: Color(hue: 0.77, saturation: 0.85, brightness: 0.9)
                )

                NetworkStatCard(
                    icon: "arrow.up.circle.fill",
                    label: "Upload",
                    value: "\(formatBytes(stats.networkUpload))/s",
                    color: Color(hue: 0.55, saturation: 0.85, brightness: 0.9)
                )
            }
            .padding(.bottom, 12)

            Divider().opacity(0.4).padding(.bottom, 10)

            // Connection details
            SectionHeader(title: "Connection")
            VStack(spacing: 4) {
                StatRow(label: "IP Address", value: stats.getLocalIP(), accent: .cyan)
                StatRow(label: "Interface", value: "en0 (Wi-Fi)")
            }
            .padding(.top, 4)
            .padding(.bottom, 12)

            Divider().opacity(0.4).padding(.bottom, 10)

            // Dual-line graph
            SectionHeader(title: "Throughput History (2 min)")
            DualLineGraph(
                primaryData: stats.networkDownloadHistory,
                secondaryData: stats.networkUploadHistory,
                primaryColor: Color(hue: 0.77, saturation: 0.85, brightness: 0.9),
                secondaryColor: Color(hue: 0.55, saturation: 0.85, brightness: 0.9),
                primaryLabel: "Download",
                secondaryLabel: "Upload",
                formatValue: { Formatters.bytes.string(fromByteCount: Int64($0)) + "/s" }
            )
            .frame(height: 90)
            .padding(.top, 4)
        }
        .padding(14)
        .frame(width: 320)
    }
}

struct NetworkStatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    @State private var hovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(hovered ? color : .primary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(color.opacity(hovered ? 0.12 : 0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(color.opacity(hovered ? 0.3 : 0.12), lineWidth: 1)
        )
        .scaleEffect(hovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: hovered)
        .onHover { hovered = $0 }
    }
}
