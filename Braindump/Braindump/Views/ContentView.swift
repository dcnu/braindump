import SwiftUI

struct ContentView: View {
	@Bindable var appState: AppState

	var body: some View {
		ZStack {
			VStack(spacing: 0) {
				ScrollView {
					DayView(appState: appState)
						.padding()
				}

				// Shortcuts hint
				HStack {
					Spacer()
					Text("CMD+/  Shortcuts")
						.font(.system(.caption2, design: .monospaced))
						.foregroundStyle(.quaternary)
						.padding(.trailing, 12)
						.padding(.bottom, 6)
				}
			}

			if appState.showingShortcuts {
				Color.black.opacity(0.3)
					.ignoresSafeArea()
					.onTapGesture {
						appState.showingShortcuts = false
					}

				ShortcutsOverlay {
					appState.showingShortcuts = false
				}
			}
		}
		.frame(minWidth: 300, minHeight: 200)
		.background(.background)
		.keyboardShortcut("n", modifiers: .command, onPress: {
			appState.startDraft()
		})
		.keyboardShortcut(.return, modifiers: .command, onPress: {
			if appState.isDrafting {
				appState.submitDraft()
			} else if appState.editingEntryID != nil {
				appState.submitEdit()
			}
		})
		.keyboardShortcut(.escape, modifiers: [], onPress: {
			if appState.showingShortcuts {
				appState.showingShortcuts = false
			} else if appState.isDrafting {
				appState.cancelDraft()
			} else if appState.editingEntryID != nil {
				appState.cancelEdit()
			}
		})
		.keyboardShortcut(.leftArrow, modifiers: .command, onPress: {
			appState.navigateDay(offset: -1)
		})
		.keyboardShortcut(.rightArrow, modifiers: .command, onPress: {
			appState.navigateDay(offset: 1)
		})
		.keyboardShortcut(.delete, modifiers: .command, onPress: {
			if let id = appState.editingEntryID {
				appState.deleteEntry(id: id)
			}
		})
		.keyboardShortcut(",", modifiers: .command, onPress: {
			NotificationCenter.default.post(name: .openSettings, object: nil)
		})
		.keyboardShortcut("/", modifiers: .command, onPress: {
			appState.showingShortcuts.toggle()
		})
	}
}

extension Notification.Name {
	static let openSettings = Notification.Name("com.dcnu.braindump.openSettings")
}

extension View {
	func keyboardShortcut(_ key: KeyEquivalent, modifiers: EventModifiers, onPress action: @escaping () -> Void) -> some View {
		self.background(
			Button("") { action() }
				.keyboardShortcut(key, modifiers: modifiers)
				.opacity(0)
				.frame(width: 0, height: 0)
		)
	}
}
