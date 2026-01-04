import SwiftUI

struct LineGraph: View {
    var data: [Double]
    var color: Color
    
    var body: some View {
        GeometryReader { geometry in
            if data.isEmpty || data.allSatisfy({ $0 == 0 }) {
                Text("No activity")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let maxVal = data.max() ?? 1.0
                let points = data.enumerated().map { item -> CGPoint in
                    let x = geometry.size.width / CGFloat(data.count - 1) * CGFloat(item.offset)
                    let y = geometry.size.height - (CGFloat(item.element) / CGFloat(maxVal == 0 ? 1 : maxVal) * geometry.size.height)
                    return CGPoint(x: x, y: y)
                }
                
                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: first)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 2)
                
                // Gradient fill
                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: first)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                    path.addLine(to: CGPoint(x: points.last?.x ?? 0, y: geometry.size.height))
                    path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
                    path.closeSubpath()
                }
                .fill(LinearGradient(gradient: Gradient(colors: [color.opacity(0.3), color.opacity(0.05)]), startPoint: .top, endPoint: .bottom))
            }
        }
    }
}
