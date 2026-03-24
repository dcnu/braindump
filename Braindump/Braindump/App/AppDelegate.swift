import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
	private var statusItem: NSStatusItem!
	private var panel: NSWindow!
	private var hotkeyManager: HotkeyManager?
	private var settingsWindow: NSWindow?
	private var localKeyMonitor: Any?
	let appState = AppState()

	func applicationDidFinishLaunching(_ notification: Notification) {
		applyAppearance(appState.settings.appearanceMode)
		logAppearance()
		setupStatusItem()
		setupPanel()
		setupHotkey()
		setupLocalKeyMonitor()

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(appDidBecomeActive),
			name: NSApplication.didBecomeActiveNotification,
			object: nil
		)

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(openSettings),
			name: .openSettings,
			object: nil
		)

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(settingsChanged),
			name: .settingsChanged,
			object: nil
		)
	}

	@objc private func settingsChanged() {
		updatePanelBackground()
		applyAppearance(appState.settings.appearanceMode)
	}

	// MARK: - Dock / CMD-Tab Reopen

	func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
		if !flag {
			showPanel()
		}
		return true
	}

	// MARK: - App-wide Key Monitor

	private func setupLocalKeyMonitor() {
		localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
			guard let self else { return event }
			let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

			// CMD+N — new entry from anywhere
			if mods == .command && event.keyCode == 45 {
				if !self.panel.isVisible {
					self.showPanel()
				}
				self.appState.startDraft()
				return nil
			}

			return event
		}
	}

	// MARK: - Status Item

	private func setupStatusItem() {
		statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

		if let button = statusItem.button {
			if let image = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: "Braindump") {
				image.isTemplate = true
				button.image = image
			} else {
				button.title = "BD"
			}
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
		menu.addItem(NSMenuItem(title: "Keyboard Shortcuts", action: #selector(showShortcuts), keyEquivalent: "/"))
		menu.addItem(NSMenuItem.separator())
		menu.addItem(NSMenuItem(title: "Quit Braindump", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

		statusItem.menu = menu
		statusItem.button?.performClick(nil)
		statusItem.menu = nil
	}

	@objc private func showShortcuts() {
		showPanel()
		appState.showingShortcuts = true
	}

	@objc private func openSettings() {
		// Always create a fresh settings window
		let settingsView = SettingsView(appState: appState)
		let window = NSWindow(
			contentRect: NSRect(x: 0, y: 0, width: 460, height: 700),
			styleMask: [.titled, .closable, .resizable],
			backing: .buffered,
			defer: false
		)
		window.title = "Braindump Settings"
		window.contentMinSize = NSSize(width: 420, height: 340)
		window.contentView = NSHostingView(rootView: settingsView)
		window.center()
		window.isReleasedWhenClosed = false
		window.delegate = self

		NSApp.activate(ignoringOtherApps: true)
		window.orderFrontRegardless()

		settingsWindow = window
	}

	// MARK: - Panel

	private func setupPanel() {
		let width = CGFloat(UserDefaults.standard.double(forKey: "panelWidth"))
		let height = CGFloat(UserDefaults.standard.double(forKey: "panelHeight"))

		panel = NSWindow(
			contentRect: NSRect(
				x: 0, y: 0,
				width: width > 0 ? width : Constants.defaultPanelWidth,
				height: height > 0 ? height : Constants.defaultPanelHeight
			),
			styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
			backing: .buffered,
			defer: false
		)

		panel.titleVisibility = .hidden
		panel.titlebarAppearsTransparent = true
		panel.isMovableByWindowBackground = true
		panel.isReleasedWhenClosed = false
		panel.minSize = NSSize(width: 300, height: 200)

		let contentView = ContentView(appState: appState)
		panel.contentView = NSHostingView(rootView: contentView)

		panel.delegate = self
	}

	@objc private func togglePanel() {
		if panel.isVisible {
			panel.orderOut(nil)
			appState.isPanelVisible = false
		} else {
			showPanel()
		}
	}

	private func updatePanelBackground() {
		let hex = appState.settings.backgroundColorHex
		panel.backgroundColor = NSColor(
			red: CGFloat(Int(hex.dropFirst().prefix(2), radix: 16) ?? 255) / 255,
			green: CGFloat(Int(hex.dropFirst(3).prefix(2), radix: 16) ?? 255) / 255,
			blue: CGFloat(Int(hex.dropFirst(5).prefix(2), radix: 16) ?? 255) / 255,
			alpha: 1
		)
	}

	private func showPanel() {
		updatePanelBackground()
		guard let screen = NSScreen.main else { return }
		let screenFrame = screen.visibleFrame
		let panelSize = panel.frame.size

		let x = screenFrame.midX - panelSize.width / 2
		let y = screenFrame.midY - panelSize.height / 2

		panel.setFrameOrigin(NSPoint(x: x, y: y))
		NSApp.activate(ignoringOtherApps: true)
		panel.makeKeyAndOrderFront(nil)
		appState.isPanelVisible = true
		appState.navigateToToday()
	}

	// MARK: - Global Hotkey

	private func setupHotkey() {
		let combo = appState.settings.globalHotkey
		hotkeyManager = HotkeyManager(
			keyCode: combo.key,
			modifierFlags: NSEvent.ModifierFlags(rawValue: combo.modifiers)
		) { [weak self] in
			DispatchQueue.main.async {
				self?.togglePanel()
			}
		}

		if HotkeyManager.checkAccessibilityOnce() {
			hotkeyManager?.start()
		}

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(hotkeyChanged),
			name: .hotkeyChanged,
			object: nil
		)
	}

	@objc private func hotkeyChanged() {
		let combo = appState.settings.globalHotkey
		hotkeyManager?.stop()
		hotkeyManager?.updateHotkey(
			keyCode: combo.key,
			modifierFlags: NSEvent.ModifierFlags(rawValue: combo.modifiers)
		)
		hotkeyManager?.start()
	}

	// MARK: - App Lifecycle

	@objc private func appDidBecomeActive() {
		appState.handleFileChange()
	}

	private func logAppearance() {
		let effective = NSApp.effectiveAppearance
		let isDark = effective.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
		let setting = appState.settings.appearanceMode.rawValue
		print("[Braindump] System appearance: \(isDark ? "Dark" : "Light"), Setting: \(setting), Effective: \(effective.name.rawValue)")
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

	func windowShouldClose(_ sender: NSWindow) -> Bool {
		if sender == panel {
			sender.orderOut(nil)
			appState.isPanelVisible = false
			return false
		}
		return true
	}

	func windowDidResignKey(_ notification: Notification) {
		guard let window = notification.object as? NSWindow,
			  window == settingsWindow else { return }
		window.orderOut(nil)
		settingsWindow = nil
	}
}
