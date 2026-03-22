import SwiftUI

struct ContentView: View {
	@Bindable var appState: AppState

	var body: some View {
		VStack(spacing: 0) {
			InputField(appState: appState)

			Divider()

			ScrollView {
				DayView(appState: appState)
					.padding()
			}
		}
		.frame(minWidth: 300, minHeight: 200)
		.background(.background)
		.keyboardShortcut(.leftArrow, modifiers: .command, onPress: {
			appState.navigateDay(offset: -1)
		})
		.keyboardShortcut(.rightArrow, modifiers: .command, onPress: {
			appState.navigateDay(offset: 1)
		})
	}
}

// Use hidden buttons for keyboard shortcuts since .onKeyPress with modifiers
// requires macOS 15+. This approach works on macOS 14+.
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
