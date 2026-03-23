import XCTest
import SwiftUI
@testable import Braindump

final class ColorExtensionsTests: XCTestCase {
	func testHexBlack() {
		let color = Color(hex: "#000000")
		XCTAssertEqual(color.toHex(), "#000000")
	}

	func testHexWhite() {
		let color = Color(hex: "#FFFFFF")
		XCTAssertEqual(color.toHex(), "#FFFFFF")
	}

	func testHexRed() {
		let color = Color(hex: "#FF0000")
		XCTAssertEqual(color.toHex(), "#FF0000")
	}

	func testHexWithoutHash() {
		let color = Color(hex: "00FF00")
		XCTAssertEqual(color.toHex(), "#00FF00")
	}

	func testInvalidHex() {
		let color = Color(hex: "xyz")
		// Should default to black
		XCTAssertEqual(color.toHex(), "#000000")
	}

	func testRoundTrip() {
		// Allow ±1 per channel due to Color<->NSColor float precision
		let hex = "#3A7BDF"
		let color = Color(hex: hex)
		let result = color.toHex()
		XCTAssertTrue(hexesCloseEnough(hex, result), "\(result) not close to \(hex)")
	}

	private func hexesCloseEnough(_ a: String, _ b: String) -> Bool {
		let aVal = UInt64(a.dropFirst(), radix: 16) ?? 0
		let bVal = UInt64(b.dropFirst(), radix: 16) ?? 0
		let ar = (aVal >> 16) & 0xFF, ag = (aVal >> 8) & 0xFF, ab = aVal & 0xFF
		let br = (bVal >> 16) & 0xFF, bg = (bVal >> 8) & 0xFF, bb = bVal & 0xFF
		return abs(Int(ar) - Int(br)) <= 1 && abs(Int(ag) - Int(bg)) <= 1 && abs(Int(ab) - Int(bb)) <= 1
	}
}
