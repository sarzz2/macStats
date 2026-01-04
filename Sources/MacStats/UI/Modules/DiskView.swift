import SwiftUI

struct DiskView: View {
    @ObservedObject var stats: StatsCollector
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Disk Usage")
                .font(.headline)
            
            Text("\(Int(stats.diskUsage * 100))%")
                .font(.title2)
                .bold()
                .foregroundColor(.purple)
            
            AdaptiveProgressBar(value: stats.diskUsage)
                 .frame(height: 12)
            
            Divider()
            
            Text("Read/Write Speed")
                .font(.subheadline)
            // Real R/W
            HStack {
                VStack(alignment: .leading) {
                    Text("Read")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("\(formatBytes(stats.diskReadSpeed))/s")
                        .bold()
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Write")
                        .font(.caption)
                        .foregroundColor(.red)
                    Text("\(formatBytes(stats.diskWriteSpeed))/s")
                        .bold()
                }
            }
            .padding(.bottom, 4)
            
            // Graph
            VStack(alignment: .leading, spacing: 4) {
                Text("Disk I/O History")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                BidirectionalGraph(
                    upData: stats.diskReadHistory,
                    downData: stats.diskWriteHistory,
                    upColor: Color.green,   // Read
                    downColor: Color.red    // Write
                )
                .frame(height: 100)
                .background(Color.black.opacity(0.05))
                .cornerRadius(6)
            }
        }
        .padding()
        .frame(width: 320)
    }
    
    func formatBytes(_ bytes: Double) -> String {
        let b = Int64(bytes)
        return Formatters.bytes.string(fromByteCount: b)
    }
}
