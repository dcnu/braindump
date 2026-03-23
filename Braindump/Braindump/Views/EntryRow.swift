import SwiftUI

struct EntryRow: View {
	let entry: Entry
	let displayTimestamp: String
	let isProcessed: Bool
	let isEditing: Bool
	@Binding var editContent: String
	var autoCorrect: Bool = false
	let onTap: () -> Void
	let onSubmit: () -> Void
	let onDelete: () -> Void

	var body: some View {
		HStack(alignment: .top, spacing: 12) {
			Text(displayTimestamp)
				.font(.system(.caption, design: .monospaced))
				.foregroundStyle(.secondary)
				.frame(width: 70, alignment: .leading)

			if isEditing {
				AutoClosingTextEditor(
					text: $editContent,
					onSubmit: onSubmit,
					autoCorrect: autoCorrect
				)
				.frame(minHeight: 24, maxHeight: 200)
			} else {
				Text(entry.content.isEmpty ? " " : entry.content)
					.font(.system(.body, design: .monospaced))
					.foregroundStyle(isProcessed ? .secondary : .primary)
					.frame(maxWidth: .infinity, alignment: .leading)
					.contentShape(Rectangle())
					.onTapGesture {
						onTap()
					}
			}
		}
		.padding(.vertical, 4)
		.opacity(isProcessed ? 0.6 : 1.0)
	}
}
