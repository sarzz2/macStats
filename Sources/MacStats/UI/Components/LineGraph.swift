import SwiftUI

// MARK: - Premium Smooth Line Graph
struct SmoothLineGraph: View {
    var data: [Double]
    var color: Color
    var label: String = ""
    var formatValue: (Double) -> String = { String(format: "%.1f%%", $0 * 100) }
    var maxOverride: Double? = nil
    var showGrid: Bool = true

    @State private var hoverIndex: Int? = nil
    @State private var hoverPos: CGFloat = 0

    private var displayData: [Double] { data.isEmpty ? [0] : data }
    private var maxVal: Double { maxOverride ?? max(displayData.max() ?? 1.0, 0.001) }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let pts = points(in: geo.size)

                ZStack(alignment: .topLeading) {
                    // Grid lines
                    if showGrid {
                        ForEach([0.25, 0.5, 0.75], id: \.self) { frac in
                            Path { p in
                                let y = h * CGFloat(1 - frac)
                                p.move(to: CGPoint(x: 0, y: y))
                                p.addLine(to: CGPoint(x: w, y: y))
                            }
                            .stroke(Color.primary.opacity(0.07), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        }
                    }

                    // Gradient fill below line
                    if pts.count > 1 {
                        filledPath(pts: pts, height: h)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [color.opacity(0.35), color.opacity(0.02)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        // Smooth stroke
                        smoothPath(pts: pts)
                            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 2)
                    }

                    // Hover vertical line + dot
                    if let idx = hoverIndex, idx < pts.count {
                        let pt = pts[idx]

                        // Vertical line
                        Path { p in
                            p.move(to: CGPoint(x: pt.x, y: 0))
                            p.addLine(to: CGPoint(x: pt.x, y: h))
                        }
                        .stroke(Color.primary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))

                        // Dot
                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)
                            .shadow(color: color.opacity(0.5), radius: 3)
                            .position(pt)

                        // Tooltip
                        let tooltipX = min(max(pt.x, 50), w - 50)
                        let val = displayData[idx]
                        Text(formatValue(val))
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .shadow(radius: 4)
                            .position(x: tooltipX, y: max(pt.y - 18, 12))
                    }
                }
                .contentShape(Rectangle())
                .onHover { hovering in if !hovering { hoverIndex = nil } }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let step = w / CGFloat(max(displayData.count - 1, 1))
                            let idx = min(max(Int((value.location.x / step).rounded()), 0), displayData.count - 1)
                            hoverIndex = idx
                            hoverPos = value.location.x
                        }
                        .onEnded { _ in hoverIndex = nil }
                )
            }

            // X-axis labels
            HStack {
                Text("2m ago").font(.system(size: 8)).foregroundColor(.secondary)
                Spacer()
                if !label.isEmpty {
                    Text(label).font(.system(size: 8, weight: .medium)).foregroundColor(color)
                }
                Spacer()
                Text("Now").font(.system(size: 8)).foregroundColor(.secondary)
            }
            .padding(.top, 3)
        }
    }

    private func points(in size: CGSize) -> [CGPoint] {
        let count = displayData.count
        guard count > 0 else { return [] }
        return displayData.enumerated().map { (i, val) in
            let x = count <= 1 ? size.width / 2 : size.width * CGFloat(i) / CGFloat(count - 1)
            let y = size.height * CGFloat(1 - min(max(val / maxVal, 0), 1))
            return CGPoint(x: x, y: y)
        }
    }

    private func smoothPath(pts: [CGPoint]) -> Path {
        Path { path in
            guard pts.count > 1 else { return }
            path.move(to: pts[0])
            for i in 1..<pts.count {
                let prev = pts[i - 1]
                let curr = pts[i]
                let cpX = (prev.x + curr.x) / 2
                path.addCurve(to: curr,
                               control1: CGPoint(x: cpX, y: prev.y),
                               control2: CGPoint(x: cpX, y: curr.y))
            }
        }
    }

    private func filledPath(pts: [CGPoint], height: CGFloat) -> Path {
        Path { path in
            guard pts.count > 1 else { return }
            path.move(to: CGPoint(x: pts[0].x, y: height))
            path.addLine(to: pts[0])
            for i in 1..<pts.count {
                let prev = pts[i - 1]
                let curr = pts[i]
                let cpX = (prev.x + curr.x) / 2
                path.addCurve(to: curr,
                               control1: CGPoint(x: cpX, y: prev.y),
                               control2: CGPoint(x: cpX, y: curr.y))
            }
            path.addLine(to: CGPoint(x: pts.last!.x, y: height))
            path.closeSubpath()
        }
    }
}

// MARK: - Dual Smooth Line Graph (upload/download, read/write)
struct DualLineGraph: View {
    var primaryData: [Double]
    var secondaryData: [Double]
    var primaryColor: Color
    var secondaryColor: Color
    var primaryLabel: String
    var secondaryLabel: String
    var formatValue: (Double) -> String

    @State private var hoverIndex: Int? = nil

    private var allData: [Double] { primaryData + secondaryData }
    private var maxVal: Double { max(allData.max() ?? 1.0, 0.001) }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                let primPts = computePoints(data: primaryData, size: geo.size)
                let secPts = computePoints(data: secondaryData, size: geo.size)

                ZStack {
                    // Grid
                    ForEach([0.25, 0.5, 0.75], id: \.self) { frac in
                        Path { p in
                            let y = h * CGFloat(1 - frac)
                            p.move(to: CGPoint(x: 0, y: y))
                            p.addLine(to: CGPoint(x: w, y: y))
                        }
                        .stroke(Color.primary.opacity(0.07), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }

                    // Secondary fill
                    if secPts.count > 1 {
                        filledPath(pts: secPts, height: h)
                            .fill(LinearGradient(gradient: Gradient(colors: [secondaryColor.opacity(0.2), secondaryColor.opacity(0.01)]), startPoint: .top, endPoint: .bottom))
                        smoothPath(pts: secPts)
                            .stroke(secondaryColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                    }

                    // Primary fill
                    if primPts.count > 1 {
                        filledPath(pts: primPts, height: h)
                            .fill(LinearGradient(gradient: Gradient(colors: [primaryColor.opacity(0.28), primaryColor.opacity(0.02)]), startPoint: .top, endPoint: .bottom))
                        smoothPath(pts: primPts)
                            .stroke(primaryColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            .shadow(color: primaryColor.opacity(0.4), radius: 3)
                    }

                    // Hover
                    if let idx = hoverIndex, idx < primPts.count, idx < secPts.count {
                        let pt = primPts[idx]
                        Path { p in
                            p.move(to: CGPoint(x: pt.x, y: 0))
                            p.addLine(to: CGPoint(x: pt.x, y: h))
                        }
                        .stroke(Color.primary.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))

                        Circle().fill(primaryColor).frame(width: 7, height: 7).position(pt)
                        Circle().fill(secondaryColor).frame(width: 7, height: 7).position(secPts[idx])

                        let pVal = primaryData[idx]
                        let sVal = secondaryData[idx]
                        let tooltipX = min(max(pt.x, 60), w - 60)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Circle().fill(primaryColor).frame(width: 6, height: 6)
                                Text(formatValue(pVal)).font(.system(size: 10, weight: .semibold))
                            }
                            HStack(spacing: 4) {
                                Circle().fill(secondaryColor).frame(width: 6, height: 6)
                                Text(formatValue(sVal)).font(.system(size: 10, weight: .semibold))
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .shadow(radius: 5)
                        .position(x: tooltipX, y: max(pt.y - 28, 28))
                    }
                }
                .contentShape(Rectangle())
                .onHover { hovering in if !hovering { hoverIndex = nil } }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let step = w / CGFloat(max(primaryData.count - 1, 1))
                            hoverIndex = min(max(Int((value.location.x / step).rounded()), 0), primaryData.count - 1)
                        }
                        .onEnded { _ in hoverIndex = nil }
                )
            }

            HStack {
                HStack(spacing: 4) {
                    Circle().fill(primaryColor).frame(width: 6, height: 6)
                    Text(primaryLabel).font(.system(size: 8)).foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(secondaryColor).frame(width: 6, height: 6)
                    Text(secondaryLabel).font(.system(size: 8)).foregroundColor(.secondary)
                }
            }
            .padding(.top, 3)
        }
    }

    private func computePoints(data: [Double], size: CGSize) -> [CGPoint] {
        let count = data.count
        guard count > 0 else { return [] }
        return data.enumerated().map { (i, val) in
            let x = count <= 1 ? size.width / 2 : size.width * CGFloat(i) / CGFloat(count - 1)
            let y = size.height * CGFloat(1 - min(max(val / maxVal, 0), 1))
            return CGPoint(x: x, y: y)
        }
    }

    private func smoothPath(pts: [CGPoint]) -> Path {
        Path { path in
            guard pts.count > 1 else { return }
            path.move(to: pts[0])
            for i in 1..<pts.count {
                let prev = pts[i - 1]; let curr = pts[i]
                let cpX = (prev.x + curr.x) / 2
                path.addCurve(to: curr, control1: CGPoint(x: cpX, y: prev.y), control2: CGPoint(x: cpX, y: curr.y))
            }
        }
    }

    private func filledPath(pts: [CGPoint], height: CGFloat) -> Path {
        Path { path in
            guard pts.count > 1 else { return }
            path.move(to: CGPoint(x: pts[0].x, y: height))
            path.addLine(to: pts[0])
            for i in 1..<pts.count {
                let prev = pts[i - 1]; let curr = pts[i]
                let cpX = (prev.x + curr.x) / 2
                path.addCurve(to: curr, control1: CGPoint(x: cpX, y: prev.y), control2: CGPoint(x: cpX, y: curr.y))
            }
            path.addLine(to: CGPoint(x: pts.last!.x, y: height))
            path.closeSubpath()
        }
    }
}
