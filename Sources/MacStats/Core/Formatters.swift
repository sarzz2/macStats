import Foundation

struct Formatters {
    static let bytes: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.allowedUnits = [.useAll]
        f.countStyle = .memory
        return f
    }()
    
    // Helper for consistency
    static func formatBytes(_ value: Double) -> String {
        return bytes.string(fromByteCount: Int64(value))
    }
}
