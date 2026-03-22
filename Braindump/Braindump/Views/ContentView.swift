import SwiftUI

struct ContentView: View {
	@Bindable var appState: AppState

	var body: some View {
		ScrollView {
			DayView(appState: appState)
				.padding()
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
			if appState.isDrafting {
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
	}
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
