import SwiftUI

struct ShortcutsOverlay: View {
	let globalHotkeyDisplay: String
	let onDismiss: () -> Void

	private var shortcuts: [(String, [(String, String)])] {
		[
		("Global", [
			(globalHotkeyDisplay, "Toggle panel"),
		]),
		("Entries", [
			("CMD + N", "New entry"),
			("CMD + Enter", "Submit entry"),
			("Escape", "Cancel draft / edit"),
			("CMD + Delete", "Delete entry"),
		]),
		("Navigation", [
			("CMD + Left", "Previous day"),
			("CMD + Right", "Next day"),
		]),
		("App", [
			("CMD + ,", "Settings"),
			("CMD + /", "Keyboard shortcuts"),
			("CMD + Q", "Quit"),
		]),
		]
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			HStack {
				Text("Keyboard Shortcuts")
					.font(.system(.title3, design: .monospaced, weight: .bold))

				Spacer()

				Button {
					onDismiss()
				} label: {
					Image(systemName: "xmark.circle.fill")
						.foregroundStyle(.secondary)
						.font(.title3)
				}
				.buttonStyle(.plain)
			}

			ForEach(shortcuts, id: \.0) { section in
				VStack(alignment: .leading, spacing: 6) {
					Text(section.0)
						.font(.system(.caption, design: .monospaced))
						.foregroundStyle(.tertiary)
						.textCase(.uppercase)

					ForEach(section.1, id: \.0) { shortcut in
						HStack {
							Text(shortcut.0)
								.font(.system(.body, design: .monospaced))
								.foregroundStyle(.secondary)
								.frame(width: 150, alignment: .trailing)

							Text(shortcut.1)
								.font(.system(.body, design: .monospaced))
						}
					}
				}
			}
		}
		.padding(24)
		.background(
			RoundedRectangle(cornerRadius: 12)
				.fill(.ultraThickMaterial)
				.shadow(radius: 20)
		)
		.frame(maxWidth: 380)
	}
}
