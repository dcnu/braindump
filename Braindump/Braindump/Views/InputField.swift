import SwiftUI

struct InputField: View {
	@Bindable var appState: AppState

	var body: some View {
		VStack(spacing: 0) {
			EditorTextView(
				text: $appState.draftContent,
				onSubmit: { submitDraft() },
				isEditable: !appState.isCurrentDayProcessed
			)
			.frame(minHeight: 32, maxHeight: 120)

			HStack {
				Spacer()

				Button("CMD+N") {
					_ = appState.createEntry()
				}
				.buttonStyle(.plain)
				.font(.system(.caption2, design: .monospaced))
				.foregroundStyle(.quaternary)
				.disabled(appState.isCurrentDayProcessed)
			}
			.padding(.horizontal, 12)
			.padding(.bottom, 4)
		}
		.padding(.horizontal, 12)
		.padding(.top, 8)
	}

	private func submitDraft() {
		let content = appState.draftContent.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !content.isEmpty else { return }

		if let id = appState.createEntry() {
			appState.updateEntryContent(id: id, content: content)
			appState.submitEntry()
			appState.draftContent = ""
		}
	}
}
