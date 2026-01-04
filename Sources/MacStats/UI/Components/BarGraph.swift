import SwiftUI

// MARK: - Bar Graph (Interactive)
// MARK: - Bar Graph (Interactive)
struct BarGraph: View {
    var data: [Double]
    var color: Color
    var maxValue: Double = 1.0
    
    @State private var hoverValue: Double? = nil
    @State private var hoverPos: CGPoint = .zero
    
    var body: some View {
        VStack(spacing: 2) {
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let barWidth = width / CGFloat(max(data.count, 1))
                
                ZStack(alignment: .bottomLeading) {
                    // Bars
                    HStack(alignment: .bottom, spacing: 1) {
                        ForEach(0..<data.count, id: \.self) { i in
                            let val = data[i]
                            let h = CGFloat(min(max(val / maxValue, 0), 1)) * height
                            
                            Rectangle()
                                .fill(color)
                                .frame(width: max(0, barWidth - 1), height: h)
                                .opacity(hoverIndex(at: hoverPos.x, total: data.count, width: width) == i ? 1.0 : 0.6)
                        }
                    }
                    
                    // Hover Overlay (with safe checks)
                    if let val = hoverValue {
                        Text(String(format: "%.1f%%", val * 100))
                            .font(.caption2)
                            .padding(4)
                            .background(Color.black.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                            .position(x: min(max(hoverPos.x, 20), width - 20), y: 10)
                    }
                }
                .contentShape(Rectangle())
                .onHover { hovering in if !hovering { hoverValue = nil } }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let idx = self.hoverIndex(at: value.location.x, total: data.count, width: width)
                            if idx >= 0 && idx < data.count {
                                self.hoverValue = data[idx]
                                self.hoverPos = value.location
                            }
                        }
                        .onEnded { _ in self.hoverValue = nil }
                )
            }
            
            // X-Axis
            HStack {
                Text("60s ago").font(.system(size: 8)).foregroundColor(.secondary)
                Spacer()
                Text("Now").font(.system(size: 8)).foregroundColor(.secondary)
            }
        }
    }
    
    private func hoverIndex(at x: CGFloat, total: Int, width: CGFloat) -> Int {
        if total == 0 { return -1 }
        let step = width / CGFloat(total)
        return Int(x / step)
    }
}

// MARK: - Bidirectional Graph (Interactive)
struct BidirectionalGraph: View {
    var upData: [Double]
    var downData: [Double]
    var upColor: Color
    var downColor: Color
    
    @State private var hoverValue: String? = nil
    @State private var hoverPos: CGPoint = .zero
    
    var body: some View {
        VStack(spacing: 2) {
            GeometryReader { geometry in
                let midY = geometry.size.height / 2
                let count = upData.count
                let barW = geometry.size.width / CGFloat(max(count, 1))
                
                ZStack {
                    // Center Line
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: midY))
                        p.addLine(to: CGPoint(x: geometry.size.width, y: midY))
                    }
                    .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                    
                    // Bars
                    HStack(spacing: 0) {
                        ForEach(0..<count, id: \.self) { i in
                            let upVal = CGFloat(upData[i])
                            let downVal = CGFloat(downData[i])
                            
                            let upH = logScale(upVal, height: midY)
                            let downH = logScale(downVal, height: midY)
                            
                            VStack(spacing: 0) {
                                // Up Bar (Read/Rx) - Above line
                                Rectangle()
                                    .fill(upColor)
                                    .frame(width: max(0, barW - 1), height: min(midY, upH))
                                
                                // Down Bar (Write/Tx) - Below line
                                Rectangle()
                                    .fill(downColor)
                                    .frame(width: max(0, barW - 1), height: min(midY, downH))
                            }
                            .frame(width: barW, height: geometry.size.height)
                        }
                    }
                    
                    // Hover Tip
                    if let txt = hoverValue {
                        Text(txt)
                            .font(.caption2)
                            .padding(4)
                            .background(Color.black.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                            .position(x: min(max(hoverPos.x, 30), geometry.size.width - 30), y: 10)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let idx = Int(value.location.x / barW)
                            if idx >= 0 && idx < count {
                                let up = formatBytes(upData[idx])
                                let down = formatBytes(downData[idx])
                                self.hoverValue = "⬆\(up)\n⬇\(down)"
                                self.hoverPos = value.location
                            }
                        }
                        .onEnded { _ in hoverValue = nil }
                )
            }
            
            // X-Axis
            HStack {
                Text("60s ago").font(.system(size: 8)).foregroundColor(.secondary)
                Spacer()
                Text("Now").font(.system(size: 8)).foregroundColor(.secondary)
            }
        }
    }
    
    func logScale(_ val: CGFloat, height: CGFloat) -> CGFloat {
        if val <= 0 { return 0 }
        let logVal = log10(val + 1)
        return (logVal / 9.0) * height 
    }
    
    func formatBytes(_ val: Double) -> String {
        if val == 0 { return "0" }
        let b = Int64(val)
        return Formatters.bytes.string(fromByteCount: b)
    }
}
