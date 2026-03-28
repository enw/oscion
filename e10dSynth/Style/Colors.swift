import SwiftUI

extension Color {
    static let synthBg       = Color(hex: "#0a0a0a")
    static let synthGrid     = Color(hex: "#1a2a1a")
    static let synthGreen    = Color(hex: "#00ff88")
    static let synthAmber    = Color(hex: "#ffaa00")
    static let synthRed      = Color(hex: "#ff4444")
    static let synthDimGreen = Color(hex: "#004422")
    static let synthDimAmber = Color(hex: "#332200")
    static let synthPanel    = Color(hex: "#0f1a0f")
    static let synthBorder   = Color(hex: "#1e3a1e")
    static let synthText     = Color(hex: "#88cc88")
    static let synthBlue     = Color(red: 0.2, green: 0.6, blue: 1.0)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

extension Color {
    static func signalColor(_ type: SignalType) -> Color {
        switch type {
        case .audio: return .synthGreen
        case .cv:    return .synthAmber
        case .gate:  return .synthRed
        }
    }
}
