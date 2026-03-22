import SwiftUI

struct InputField: View {
	@Bindable var appState: AppState

	var body: some View {
		HStack(spacing: 8) {
			TextField("New entry...", text: $appState.draftContent, axis: .vertical)
				.textFieldStyle(.plain)
				.font(.system(.body, design: .monospaced))
				.lineLimit(1...5)
				.disabled(appState.isCurrentDayProcessed)

			Button("now") {
				_ = appState.createEntry()
				if !appState.draftContent.isEmpty {
					appState.updateEntryContent(
						id: appState.editingEntryID!,
						content: appState.draftContent
					)
					appState.submitEntry()
					appState.draftContent = ""
				}
			}
			.buttonStyle(.plain)
			.font(.system(.caption, design: .monospaced))
			.foregroundStyle(.secondary)
			.disabled(appState.isCurrentDayProcessed)
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 8)
	}
}
