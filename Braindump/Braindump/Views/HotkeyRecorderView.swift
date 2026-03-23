import SwiftUI
import AppKit

struct HotkeyRecorderView: NSViewRepresentable {
	@Binding var isRecording: Bool
	let onRecord: (KeyCombo) -> Void

	func makeNSView(context: Context) -> HotkeyCapture {
		let view = HotkeyCapture()
		view.onKeyCombo = { combo in
			DispatchQueue.main.async {
				self.onRecord(combo)
				self.isRecording = false
			}
		}
		context.coordinator.view = view
		return view
	}

	func updateNSView(_ nsView: HotkeyCapture, context: Context) {
		if isRecording {
			nsView.window?.makeFirstResponder(nsView)
		}
	}

	func makeCoordinator() -> Coordinator {
		Coordinator()
	}

	final class Coordinator {
		var view: HotkeyCapture?
	}
}

final class HotkeyCapture: NSView {
	var onKeyCombo: ((KeyCombo) -> Void)?

	override var acceptsFirstResponder: Bool { true }

	override func keyDown(with event: NSEvent) {
		let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

		// Require at least one modifier key
		guard modifiers.contains(.control) || modifiers.contains(.option) ||
			  modifiers.contains(.command) || modifiers.contains(.shift) else {
			super.keyDown(with: event)
			return
		}

		// Ignore bare modifier presses (no actual key)
		guard event.keyCode != 56 && event.keyCode != 57 && event.keyCode != 58 &&
			  event.keyCode != 59 && event.keyCode != 55 && event.keyCode != 54 &&
			  event.keyCode != 63 && event.keyCode != 61 && event.keyCode != 62 &&
			  event.keyCode != 60 else {
			return
		}

		let combo = KeyCombo(key: event.keyCode, modifiers: modifiers.rawValue)
		onKeyCombo?(combo)
	}
}
