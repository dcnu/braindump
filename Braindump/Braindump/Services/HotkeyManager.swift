import AppKit

final class HotkeyManager {
	private var globalMonitor: Any?
	private var localMonitor: Any?
	private var keyCode: UInt16
	private var modifierFlags: NSEvent.ModifierFlags
	private let action: () -> Void

	init(keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags, action: @escaping () -> Void) {
		self.keyCode = keyCode
		self.modifierFlags = modifierFlags
		self.action = action
	}

	deinit {
		stop()
	}

	func start() {
		stop()

		globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
			self?.handleEvent(event)
		}

		localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
			if self?.handleEvent(event) == true {
				return nil
			}
			return event
		}
	}

	func stop() {
		if let monitor = globalMonitor {
			NSEvent.removeMonitor(monitor)
			globalMonitor = nil
		}
		if let monitor = localMonitor {
			NSEvent.removeMonitor(monitor)
			localMonitor = nil
		}
	}

	func updateHotkey(keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags) {
		self.keyCode = keyCode
		self.modifierFlags = modifierFlags
	}

	@discardableResult
	private func handleEvent(_ event: NSEvent) -> Bool {
		let eventModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
		if event.keyCode == keyCode && eventModifiers == modifierFlags {
			action()
			return true
		}
		return false
	}

	static func checkAccessibility() -> Bool {
		let trusted = AXIsProcessTrusted()
		if !trusted {
			let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
			AXIsProcessTrustedWithOptions(options)
		}
		return trusted
	}
}
