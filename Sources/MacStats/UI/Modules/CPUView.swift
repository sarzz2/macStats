import SwiftUI

struct CPUView: View {
    @ObservedObject var stats: StatsCollector
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            Text("CPU Usage")
                .font(.headline)
            
            // Total Load
            HStack {
                Text(String(format: "total: %.1f%%", stats.cpuUsage * 100))
                    .font(.title2)
                    .bold()
                Spacer()
            }
            
            AdaptiveProgressBar(value: stats.cpuUsage)
                .frame(height: 12)
            
            Divider()
            
            // Cores Grid
            Text("Cores")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(0..<stats.cpuPerCore.count, id: \.self) { i in
                    let usage = stats.cpuPerCore[i]
                    VStack(spacing: 2) {
                        AdaptiveProgressBar(value: usage)
                            .frame(height: 4)
                        Text("\(Int(usage * 100))%")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.bottom, 4)
            
            Divider()
            
            // Top Processes
            VStack(alignment: .leading, spacing: 4) {
                Text("Top Processes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(stats.topCpuProcesses) { process in
                    HStack {
                        if let icon = process.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "gear")
                                .resizable()
                                .frame(width: 16, height: 16)
                        }
                        
                        Text(process.name)
                            .font(.caption)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(String(format: "%.1f%%", process.usage))
                            .font(.caption)
                            .bold()
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .frame(width: 320)
    }
}

struct MainBar: View {
    var value: Double
    var color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                Rectangle().frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.1)
                    .foregroundColor(color)
                
                Rectangle().frame(width: geometry.size.width, height: min(CGFloat(self.value)*geometry.size.height, geometry.size.height))
                    .foregroundColor(color)
            }
            .cornerRadius(4)
        }
    }
}
