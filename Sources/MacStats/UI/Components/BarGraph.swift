import SwiftUI

// BarGraph is kept as a thin wrapper for backward compatibility.
// All new graphs use SmoothLineGraph or DualLineGraph from LineGraph.swift.

struct BarGraph: View {
    var data: [Double]
    var color: Color
    var maxValue: Double = 1.0
    var formatValue: (Double) -> String = { String(format: "%.1f%%", $0 * 100) }

    var body: some View {
        SmoothLineGraph(data: data, color: color, formatValue: formatValue, maxOverride: maxValue)
    }
}

struct BidirectionalGraph: View {
    var upData: [Double]
    var downData: [Double]
    var upColor: Color
    var downColor: Color

    var body: some View {
        DualLineGraph(
            primaryData: upData,
            secondaryData: downData,
            primaryColor: upColor,
            secondaryColor: downColor,
            primaryLabel: "Up",
            secondaryLabel: "Down",
            formatValue: { Formatters.bytes.string(fromByteCount: Int64($0)) + "/s" }
        )
    }
}
