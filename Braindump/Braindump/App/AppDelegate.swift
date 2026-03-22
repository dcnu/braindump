import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
	private var statusItem: NSStatusItem!
	private var panel: FloatingPanel!

	func applicationDidFinishLaunching(_ notification: Notification) {
		setupStatusItem()
		setupPanel()
	}

	private func setupStatusItem() {
		statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

		if let button = statusItem.button {
			button.image = NSImage(
				systemSymbolName: "brain.head.profile",
				accessibilityDescription: "Braindump"
			)
			button.action = #selector(togglePanel)
			button.target = self
		}
	}

	private func setupPanel() {
		let width: CGFloat = UserDefaults.standard.object(forKey: "panelWidth") as? CGFloat ?? 400
		let height: CGFloat = UserDefaults.standard.object(forKey: "panelHeight") as? CGFloat ?? 500

		panel = FloatingPanel(
			contentRect: NSRect(x: 0, y: 0, width: width, height: height),
			styleMask: [.titled, .resizable, .fullSizeContentView, .nonactivatingPanel],
			backing: .buffered,
			defer: false
		)

		panel.titleVisibility = .hidden
		panel.titlebarAppearsTransparent = true
		panel.isMovableByWindowBackground = true
		panel.level = .floating
		panel.isReleasedWhenClosed = false
		panel.animationBehavior = .utilityWindow

		let contentView = ContentView()
		panel.contentView = NSHostingView(rootView: contentView)

		panel.delegate = self
	}

	@objc private func togglePanel() {
		if panel.isVisible {
			dismissPanel()
		} else {
			showPanel()
		}
	}

	private func showPanel() {
		guard let button = statusItem.button,
			  let buttonWindow = button.window else { return }

		let buttonFrame = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
		let panelSize = panel.frame.size

		let x = buttonFrame.midX - panelSize.width / 2
		let y = buttonFrame.minY - panelSize.height - 4

		panel.setFrameOrigin(NSPoint(x: x, y: y))
		panel.makeKeyAndOrderFront(nil)

		NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
			guard let self, self.panel.isVisible else { return }
			if !self.panel.frame.contains(event.locationInWindow) {
				self.dismissPanel()
			}
		}
	}

	private func dismissPanel() {
		panel.orderOut(nil)
	}
}

extension AppDelegate: NSWindowDelegate {
	func windowDidResize(_ notification: Notification) {
		guard let window = notification.object as? NSWindow, window == panel else { return }
		UserDefaults.standard.set(window.frame.width, forKey: "panelWidth")
		UserDefaults.standard.set(window.frame.height, forKey: "panelHeight")
	}
}

final class FloatingPanel: NSPanel {
	override var canBecomeKey: Bool { true }

	override func cancelOperation(_ sender: Any?) {
		orderOut(nil)
	}
}
