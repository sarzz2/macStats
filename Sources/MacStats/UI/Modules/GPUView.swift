import SwiftUI

struct GPUView: View {
    @ObservedObject var stats: StatsCollector
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("GPU Dashboard")
                    .font(.headline)
                Spacer()
                Image(systemName: "cpu.fill")
                    .foregroundColor(.pink)
            }
            
            // Main Gauge
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: CGFloat(stats.gpuUsage))
                    .stroke(Color.pink, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: stats.gpuUsage)
                
                VStack {
                    Text("\(Int(stats.gpuUsage * 100))%")
                        .font(.largeTitle)
                        .bold()
                    Text("Load")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            
            Divider()
            
            // Stats Grid
            HStack(spacing: 20) {
                // Temp
                VStack {
                    Image(systemName: "thermometer")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("\(Int(stats.gpuTemp))°C")
                        .font(.title3)
                        .bold()
                    Text("Temp")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Memory (Simulated or Placeholder as ioreg doesn't always give it)
                VStack {
                    Image(systemName: "memorychip")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("Dynamic")
                        .font(.caption)
                        .bold()
                        .padding(.top, 4)
                    Text("Memory")
                        .font(.caption) // Fixed duplication
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(width: 280) // Compact width
    }
}
