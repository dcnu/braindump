import SwiftUI
import ServiceManagement
import AppKit

struct SettingsView: View {
	@Bindable var appState: AppState

	private let monoFonts = [
		"SF Mono",
		"Menlo",
		"Monaco",
		"Courier New",
		"Andale Mono",
		"Source Code Pro",
		"Fira Code",
		"JetBrains Mono",
	]

	var body: some View {
		Form {
			storageSection
			appearanceSection
			fontSection
			entriesSection
			hotkeySection
			startupSection
		}
		.formStyle(.grouped)
	}

	// MARK: - Storage

	private var storageSection: some View {
		Section("Storage") {
			VStack(alignment: .leading, spacing: 8) {
				HStack {
					Text("Notes directory")
					Spacer()
					Button("Choose...") {
						chooseVaultPath()
					}
				}

				Text(appState.settings.braindumpURL.path)
					.font(.system(.caption, design: .monospaced))
					.foregroundStyle(.secondary)
					.textSelection(.enabled)

				Text("Point to an iCloud Drive folder for automatic sync, or a git-tracked directory for version control.")
					.font(.caption2)
					.foregroundStyle(.tertiary)
			}
		}
	}

	// MARK: - Appearance

	private var appearanceSection: some View {
		Section("Appearance") {
			Picker("Theme", selection: Binding(
				get: { appState.settings.appearanceMode },
				set: { newValue in
					appState.settings.appearanceMode = newValue
					applyAppearance(newValue)
				}
			)) {
				Text("System").tag(AppearanceMode.system)
				Text("Light").tag(AppearanceMode.light)
				Text("Dark").tag(AppearanceMode.dark)
			}
			.pickerStyle(.segmented)

			HStack {
				Text("Detected system appearance")
					.foregroundStyle(.secondary)
				Spacer()
				Text(detectedAppearance)
					.font(.system(.body, design: .monospaced))
					.foregroundStyle(.secondary)
			}
		}
	}

	private var detectedAppearance: String {
		let appearance = NSApp.effectiveAppearance
		if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
			return "Dark"
		}
		return "Light"
	}

	// MARK: - Font

	private var fontSection: some View {
		Section("Font") {
			Picker("Font family", selection: Binding(
				get: { appState.settings.fontName },
				set: { appState.settings.fontName = $0 }
			)) {
				ForEach(availableFonts, id: \.self) { name in
					Text(name).tag(name)
				}
			}

			HStack {
				Text("Size")
				Spacer()
				TextField("", value: Binding(
					get: { appState.settings.fontSize },
					set: { appState.settings.fontSize = $0 }
				), format: .number)
				.frame(width: 50)
				.textFieldStyle(.roundedBorder)
				.multilineTextAlignment(.center)

				Stepper("", value: Binding(
					get: { appState.settings.fontSize },
					set: { appState.settings.fontSize = $0 }
				), in: 9...36, step: 1)
				.labelsHidden()
			}

			Text("The quick brown fox jumps over the lazy dog")
				.font(.custom(appState.settings.fontName, size: appState.settings.fontSize))
				.padding(.vertical, 4)
		}
	}

	private var availableFonts: [String] {
		monoFonts.filter { name in
			NSFont(name: name, size: 13) != nil ||
			name == "SF Mono" // SF Mono requires special access
		}
	}

	// MARK: - Entries

	private var entriesSection: some View {
		Section("Entries") {
			Toggle("Enter submits entry", isOn: Binding(
				get: { appState.settings.enterSubmits },
				set: { appState.settings.enterSubmits = $0 }
			))

			Text("When enabled, pressing Enter creates a new timestamped entry. Use Shift+Enter for newlines.")
				.font(.caption)
				.foregroundStyle(.secondary)

			Picker("Time format", selection: Binding(
				get: { appState.settings.timeFormat },
				set: { appState.settings.timeFormat = $0 }
			)) {
				Text("24-hour").tag(TimeFormat.h24)
				Text("12-hour").tag(TimeFormat.h12)
			}

			Picker("New day starts at", selection: Binding(
				get: { appState.settings.dayStartHour },
				set: { appState.settings.dayStartHour = $0 }
			)) {
				ForEach(0...6, id: \.self) { hour in
					Text("\(hour):00 AM").tag(hour)
				}
			}
		}
	}

	// MARK: - Hotkey

	@State private var isRecordingHotkey = false

	private var hotkeySection: some View {
		Section("Global Hotkey") {
			HStack {
				Text("Toggle panel")
				Spacer()

				Button {
					isRecordingHotkey = true
				} label: {
					if isRecordingHotkey {
						Text("Press a key combo...")
							.font(.system(.body, design: .monospaced))
							.foregroundStyle(.orange)
					} else {
						Text(appState.settings.globalHotkey.displayString)
							.font(.system(.body, design: .monospaced))
							.foregroundStyle(.secondary)
					}
				}
				.buttonStyle(.plain)
				.padding(.horizontal, 8)
				.padding(.vertical, 4)
				.background(
					RoundedRectangle(cornerRadius: 4)
						.fill(isRecordingHotkey ? Color.orange.opacity(0.1) : Color(.quaternaryLabelColor))
				)
			}
			.background(
				HotkeyRecorderView(isRecording: $isRecordingHotkey) { combo in
					appState.settings.globalHotkey = combo
					NotificationCenter.default.post(name: .hotkeyChanged, object: nil)
				}
				.frame(width: 0, height: 0)
			)

			Text("Click the shortcut, then press your desired key combination. Requires Accessibility permission.")
				.font(.caption)
				.foregroundStyle(.secondary)
		}
	}

	// MARK: - Startup

	private var startupSection: some View {
		Section("Startup") {
			Toggle("Launch at login", isOn: Binding(
				get: { appState.settings.launchAtLogin },
				set: { newValue in
					appState.settings.launchAtLogin = newValue
					updateLoginItem(enabled: newValue)
				}
			))
		}
	}

	// MARK: - Actions

	private func chooseVaultPath() {
		let panel = NSOpenPanel()
		panel.canChooseDirectories = true
		panel.canChooseFiles = false
		panel.canCreateDirectories = true
		panel.allowsMultipleSelection = false
		panel.message = "Choose the directory where daily notes will be stored"

		if panel.runModal() == .OK, let url = panel.url {
			appState.settings.vaultPath = url.path
			appState.reconfigure()
		}
	}

	private func updateLoginItem(enabled: Bool) {
		do {
			if enabled {
				try SMAppService.mainApp.register()
			} else {
				try SMAppService.mainApp.unregister()
			}
		} catch {
			// Login item registration can fail silently
		}
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
