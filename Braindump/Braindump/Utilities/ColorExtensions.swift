import SwiftUI

extension Color {
	init(hex: String) {
		let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
		var int: UInt64 = 0
		Scanner(string: hex).scanHexInt64(&int)

		let r, g, b, a: Double
		switch hex.count {
		case 6:
			r = Double((int >> 16) & 0xFF) / 255
			g = Double((int >> 8) & 0xFF) / 255
			b = Double(int & 0xFF) / 255
			a = 1
		case 8:
			r = Double((int >> 24) & 0xFF) / 255
			g = Double((int >> 16) & 0xFF) / 255
			b = Double((int >> 8) & 0xFF) / 255
			a = Double(int & 0xFF) / 255
		default:
			r = 0; g = 0; b = 0; a = 1
		}

		self.init(red: r, green: g, blue: b, opacity: a)
	}

	func toHex() -> String {
		guard let components = NSColor(self).usingColorSpace(.sRGB) else {
			return "#000000"
		}
		let r = Int(components.redComponent * 255)
		let g = Int(components.greenComponent * 255)
		let b = Int(components.blueComponent * 255)
		return String(format: "#%02X%02X%02X", r, g, b)
	}
}
