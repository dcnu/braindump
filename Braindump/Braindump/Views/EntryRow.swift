import SwiftUI

struct EntryRow: View {
	let entry: Entry
	let displayTimestamp: String
	let isProcessed: Bool
	let isEditing: Bool
	var isSelected: Bool = false
	@Binding var editContent: String
	var autoCorrect: Bool = false
	var fontColor: Color = .primary
	var timestampColor: Color = .secondary
	let onTap: () -> Void
	let onSubmit: () -> Void
	let onDelete: () -> Void

	var body: some View {
		HStack(alignment: .top, spacing: 12) {
			Text(displayTimestamp)
				.font(.system(.caption, design: .monospaced))
				.foregroundStyle(timestampColor)
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
					.foregroundStyle(isProcessed ? fontColor.opacity(0.4) : fontColor)
					.frame(maxWidth: .infinity, alignment: .leading)
					.contentShape(Rectangle())
					.onTapGesture {
						onTap()
					}
			}
		}
		.padding(.vertical, 4)
		.padding(.horizontal, 4)
		.background(
			RoundedRectangle(cornerRadius: 4)
				.fill(isSelected && !isEditing ? Color.accentColor.opacity(0.1) : Color.clear)
		)
		.opacity(isProcessed ? 0.6 : 1.0)
	}
}
