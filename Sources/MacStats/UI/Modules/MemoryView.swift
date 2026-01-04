import SwiftUI

struct MemoryView: View {
    @ObservedObject var stats: StatsCollector
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Memory Usage")
                .font(.headline)
            
            Text("Total Used: \(Int(stats.memoryUsage * 100))%")
                .font(.title2)
                .bold()
                .foregroundColor(.green)
            
            AdaptiveProgressBar(value: stats.memoryUsage)
                .frame(height: 12)
            
            // Detailed Breakdown
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Circle().fill(Color.orange).frame(width: 8, height: 8)
                    Text("Wired: \(formatBytes(stats.memoryDetails.wired))")
                    Spacer()
                    Circle().fill(Color.blue).frame(width: 8, height: 8)
                    Text("Active: \(formatBytes(stats.memoryDetails.active))")
                }
                HStack {
                    Circle().fill(Color.purple).frame(width: 8, height: 8)
                    Text("Compressed: \(formatBytes(stats.memoryDetails.compressed))")
                    Spacer()
                    Circle().fill(Color.gray).frame(width: 8, height: 8)
                    Text("Free: \(formatBytes(stats.memoryDetails.free))")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Divider()
            
            Text("Top Processes")
                .font(.subheadline)
            
            ForEach(stats.topMemProcesses) { process in
                HStack {
                    if let icon = process.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "memorychip")
                            .resizable()
                            .frame(width: 16, height: 16)
                    }
                    Text(process.name)
                        .lineLimit(1)
                    Spacer()
                    Text(String(format: "%.1f%%", process.usage))
                        .foregroundColor(.secondary)
                }
                .font(.caption)
            }
        }
        .padding()
        .frame(width: 320)
    }
    
    func formatBytes(_ bytes: Double) -> String {
        let b = Int64(bytes)
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: b)
    }
}
