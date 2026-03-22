import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
	private var statusItem: NSStatusItem!
	private var panel: FloatingPanel!
	private var globalMonitor: Any?
	let appState = AppState()

	func applicationDidFinishLaunching(_ notification: Notification) {
		setupStatusItem()
		setupPanel()

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(appDidBecomeActive),
			name: NSApplication.didBecomeActiveNotification,
			object: nil
		)
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
		let width = CGFloat(UserDefaults.standard.double(forKey: "panelWidth"))
		let height = CGFloat(UserDefaults.standard.double(forKey: "panelHeight"))

		panel = FloatingPanel(
			contentRect: NSRect(
				x: 0, y: 0,
				width: width > 0 ? width : Constants.defaultPanelWidth,
				height: height > 0 ? height : Constants.defaultPanelHeight
			),
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

		let contentView = ContentView(appState: appState)
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
		appState.isPanelVisible = true

		globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
			guard let self, self.panel.isVisible else { return }
			let mouseLocation = NSEvent.mouseLocation
			if !self.panel.frame.contains(mouseLocation) {
				self.dismissPanel()
			}
		}
	}

	private func dismissPanel() {
		panel.orderOut(nil)
		appState.isPanelVisible = false

		if let monitor = globalMonitor {
			NSEvent.removeMonitor(monitor)
			globalMonitor = nil
		}
	}

	@objc private func appDidBecomeActive() {
		appState.handleFileChange()
	}
}

extension AppDelegate: NSWindowDelegate {
	func windowDidResize(_ notification: Notification) {
		guard let window = notification.object as? NSWindow, window == panel else { return }
		UserDefaults.standard.set(Double(window.frame.width), forKey: "panelWidth")
		UserDefaults.standard.set(Double(window.frame.height), forKey: "panelHeight")
	}
}

final class FloatingPanel: NSPanel {
	override var canBecomeKey: Bool { true }

	override func cancelOperation(_ sender: Any?) {
		orderOut(nil)
	}
}
