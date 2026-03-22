import SwiftUI
import ServiceManagement

struct SettingsView: View {
	@Bindable var appState: AppState
	@State private var selectedFolder: URL?

	var body: some View {
		TabView {
			generalTab
				.tabItem {
					Label("General", systemImage: "gear")
				}

			displayTab
				.tabItem {
					Label("Display", systemImage: "eye")
				}

			hotkeyTab
				.tabItem {
					Label("Hotkey", systemImage: "keyboard")
				}
		}
		.frame(width: 420, height: 340)
		.padding()
	}

	// MARK: - General Tab

	private var generalTab: some View {
		Form {
			Section("Storage") {
				HStack {
					Text(appState.settings.vaultPath)
						.font(.system(.body, design: .monospaced))
						.lineLimit(1)
						.truncationMode(.middle)

					Spacer()

					Button("Choose...") {
						chooseVaultPath()
					}
				}
			}

			Section("Startup") {
				Toggle("Launch at login", isOn: Binding(
					get: { appState.settings.launchAtLogin },
					set: { newValue in
						appState.settings.launchAtLogin = newValue
						updateLoginItem(enabled: newValue)
					}
				))
			}

			Section("Day Boundary") {
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
		.formStyle(.grouped)
	}

	// MARK: - Display Tab

	private var displayTab: some View {
		Form {
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
			}

			Section("Entries") {
				Picker("Sort days by", selection: Binding(
					get: { appState.settings.sortKey },
					set: { appState.settings.sortKey = $0 }
				)) {
					Text("Created").tag(SortKey.created)
					Text("Edited").tag(SortKey.edited)
				}

				Picker("Entry order", selection: Binding(
					get: { appState.settings.entryOrder },
					set: { appState.settings.entryOrder = $0 }
				)) {
					Text("Newest first").tag(EntryOrder.reverseChronological)
					Text("Oldest first").tag(EntryOrder.chronological)
				}

				Picker("Timestamp mode", selection: Binding(
					get: { appState.settings.timestampMode },
					set: { appState.settings.timestampMode = $0 }
				)) {
					Text("Per block").tag(TimestampMode.perBlock)
					Text("Per line").tag(TimestampMode.perLine)
				}

				Picker("Time format", selection: Binding(
					get: { appState.settings.timeFormat },
					set: { appState.settings.timeFormat = $0 }
				)) {
					Text("24-hour").tag(TimeFormat.h24)
					Text("12-hour").tag(TimeFormat.h12)
				}
			}
		}
		.formStyle(.grouped)
	}

	// MARK: - Hotkey Tab

	private var hotkeyTab: some View {
		Form {
			Section("Global Hotkey") {
				HStack {
					Text("Toggle panel")
					Spacer()
					Text("Ctrl + Space")
						.font(.system(.body, design: .monospaced))
						.foregroundStyle(.secondary)
						.padding(.horizontal, 8)
						.padding(.vertical, 4)
						.background(
							RoundedRectangle(cornerRadius: 4)
								.fill(.quaternary)
						)
				}

				Text("Requires Accessibility permission in System Settings.")
					.font(.caption)
					.foregroundStyle(.secondary)
			}
		}
		.formStyle(.grouped)
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
