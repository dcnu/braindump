import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
	private var statusItem: NSStatusItem!
	private var panel: FloatingPanel!
	private var clickOutsideMonitor: Any?
	private var hotkeyManager: HotkeyManager?
	private var settingsWindow: NSWindow?
	let appState = AppState()

	func applicationDidFinishLaunching(_ notification: Notification) {
		applyAppearance(appState.settings.appearanceMode)
		setupStatusItem()
		setupPanel()
		setupHotkey()

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(appDidBecomeActive),
			name: NSApplication.didBecomeActiveNotification,
			object: nil
		)
	}

	// MARK: - Status Item

	private func setupStatusItem() {
		statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

		if let button = statusItem.button {
			button.image = NSImage(
				systemSymbolName: "brain.head.profile",
				accessibilityDescription: "Braindump"
			)
			button.action = #selector(statusItemClicked(_:))
			button.target = self
			button.sendAction(on: [.leftMouseUp, .rightMouseUp])
		}
	}

	@objc private func statusItemClicked(_ sender: NSStatusBarButton) {
		guard let event = NSApp.currentEvent else { return }

		if event.type == .rightMouseUp {
			showContextMenu()
		} else {
			togglePanel()
		}
	}

	private func showContextMenu() {
		let menu = NSMenu()
		menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
		menu.addItem(NSMenuItem.separator())
		menu.addItem(NSMenuItem(title: "Quit Braindump", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

		statusItem.menu = menu
		statusItem.button?.performClick(nil)
		statusItem.menu = nil
	}

	@objc private func openSettings() {
		if let window = settingsWindow {
			window.makeKeyAndOrderFront(nil)
			NSApp.activate(ignoringOtherApps: true)
			return
		}

		let settingsView = SettingsView(appState: appState)
		let window = NSWindow(
			contentRect: NSRect(x: 0, y: 0, width: 420, height: 340),
			styleMask: [.titled, .closable],
			backing: .buffered,
			defer: false
		)
		window.title = "Braindump Settings"
		window.contentView = NSHostingView(rootView: settingsView)
		window.center()
		window.isReleasedWhenClosed = false
		window.makeKeyAndOrderFront(nil)
		NSApp.activate(ignoringOtherApps: true)

		settingsWindow = window
	}

	// MARK: - Panel

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
		panel.minSize = NSSize(width: 300, height: 200)

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

		var x = buttonFrame.midX - panelSize.width / 2
		let y = buttonFrame.minY - panelSize.height - 4

		// Keep panel on screen
		if let screen = NSScreen.main {
			let screenFrame = screen.visibleFrame
			x = max(screenFrame.minX, min(x, screenFrame.maxX - panelSize.width))
		}

		panel.setFrameOrigin(NSPoint(x: x, y: y))
		panel.makeKeyAndOrderFront(nil)
		appState.isPanelVisible = true
		appState.navigateToToday()

		clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
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

		if let monitor = clickOutsideMonitor {
			NSEvent.removeMonitor(monitor)
			clickOutsideMonitor = nil
		}
	}

	// MARK: - Global Hotkey

	private func setupHotkey() {
		let settings = appState.settings
		hotkeyManager = HotkeyManager(
			keyCode: UInt16(KeyCombo.defaultHotkey.key),
			modifierFlags: .control
		) { [weak self] in
			DispatchQueue.main.async {
				self?.togglePanel()
			}
		}

		_ = HotkeyManager.checkAccessibility()
		hotkeyManager?.start()
	}

	// MARK: - App Lifecycle

	@objc private func appDidBecomeActive() {
		appState.handleFileChange()
	}

	private func applyAppearance(_ mode: AppearanceMode) {
		switch mode {
		case .system:
			NSApp.appearance = nil
		case .light:
			NSApp.appearance = NSAppearance(named: .aqua)
		case .dark:
			NSApp.appearance = NSAppearance(named: .darkAqua)
		}
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
