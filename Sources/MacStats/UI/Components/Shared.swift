import SwiftUI

// MARK: - Premium Adaptive Progress Bar
struct AdaptiveProgressBar: View {
    var value: Double
    var color: Color? = nil

    @State private var isHovered: Bool = false

    var body: some View {
        let displayColor = color ?? colorForValue(value)

        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(displayColor.opacity(0.12))
                    .frame(width: geometry.size.width, height: geometry.size.height)

                // Fill with gradient
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [displayColor, displayColor.opacity(0.75)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: min(CGFloat(value) * geometry.size.width, geometry.size.width),
                        height: geometry.size.height
                    )
                    .animation(.spring(response: 0.5, dampingFraction: 0.75), value: value)

                // Glow on hover
                if isHovered {
                    Capsule()
                        .fill(displayColor.opacity(0.15))
                        .frame(width: geometry.size.width, height: geometry.size.height + 4)
                        .blur(radius: 3)
                }
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) { isHovered = hovering }
        }
    }

    func colorForValue(_ v: Double) -> Color {
        if v < 0.4 { return Color(hue: 0.38, saturation: 0.8, brightness: 0.75) }  // Teal-green
        if v < 0.65 { return Color(hue: 0.55, saturation: 0.85, brightness: 0.9) } // Vivid blue
        if v < 0.80 { return Color(hue: 0.08, saturation: 0.95, brightness: 0.95) } // Warm amber
        return Color(hue: 0.0, saturation: 0.9, brightness: 0.9)                    // Alert red
    }
}

// MARK: - Stat Row (reusable metric row with label, value, optional bar)
struct StatRow: View {
    let label: String
    let value: String
    var accent: Color = .secondary
    var showIndicator: Bool = false
    var indicatorColor: Color = .clear

    @State private var isHovered = false

    var body: some View {
        HStack {
            if showIndicator {
                Circle()
                    .fill(indicatorColor)
                    .frame(width: 7, height: 7)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isHovered ? accent : .primary)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .padding(.vertical, 1)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .tracking(0.8)
            .padding(.top, 4)
    }
}

// MARK: - Mini Badge
struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}
