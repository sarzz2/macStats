import SwiftUI

struct AdaptiveProgressBar: View {
    var value: Double
    var color: Color? = nil // Optional override
    
    var body: some View {
        let displayColor = color ?? colorForValue(value)
        
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Capsule()
                    .frame(width: geometry.size.width , height: geometry.size.height)
                    .opacity(0.1)
                    .foregroundColor(displayColor)
                
                // Fill
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [displayColor, displayColor.opacity(0.7)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: min(CGFloat(self.value)*geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .animation(.spring(), value: value)
            }
        }
    }
    
    func colorForValue(_ v: Double) -> Color {
        if v < 0.4 { return .green }
        if v < 0.7 { return .yellow }
        if v < 0.9 { return .orange }
        return .red
    }
}
