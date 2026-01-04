import SwiftUI

struct NetworkView: View {
    @ObservedObject var stats: StatsCollector
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Network")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.purple)
                        VStack(alignment: .leading) {
                            Text("Download")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(formatBytes(stats.networkDownload))/s")
                                .font(.title2)
                                .bold()
                        }
                    }
                }
                Spacer()
                VStack(alignment: .trailing) {
                    HStack {
                        Text("Upload")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.blue)
                    }
                    Text("\(formatBytes(stats.networkUpload))/s")
                        .font(.title2)
                        .bold()
                }
            }
            .padding(.top)
            
            Spacer()
            
            Divider()
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text("Details")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("IP Address:")
                        .font(.caption)
                    Spacer()
                    Text(stats.getLocalIP())
                        .font(.caption)
                        .bold()
                }
                HStack {
                    Text("Interface:")
                        .font(.caption)
                    Spacer()
                    Text("Wi-Fi (en0)") // Simplified as we check en0 in service
                        .font(.caption)
                        .bold()
                }
            }
            
            // Graph
            VStack(alignment: .leading, spacing: 4) {
                Text("History")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                BidirectionalGraph(
                    upData: stats.networkUploadHistory,
                    downData: stats.networkDownloadHistory,
                    upColor: Color.blue,
                    downColor: Color.purple
                )
                .frame(height: 80)
                .background(Color.black.opacity(0.05))
                .cornerRadius(6)
            }
        }
        .padding()
        .frame(width: 320) // dynamic height
    }
    
    func formatBytes(_ bytes: Double) -> String {
        let b = Int64(bytes)
        return Formatters.bytes.string(fromByteCount: b)
    }
}
