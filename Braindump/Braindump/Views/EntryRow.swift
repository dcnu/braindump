import SwiftUI

struct EntryRow: View {
	let entry: Entry
	let displayTimestamp: String
	let isProcessed: Bool
	let isEditing: Bool
	let onTap: () -> Void
	let onContentChange: (String) -> Void
	let onSubmit: () -> Void
	let onDelete: () -> Void

	var body: some View {
		HStack(alignment: .top, spacing: 12) {
			Text(displayTimestamp)
				.font(.system(.caption, design: .monospaced))
				.foregroundStyle(.secondary)
				.frame(width: 70, alignment: .leading)

			if isEditing {
				TextField("", text: Binding(
					get: { entry.content },
					set: { onContentChange($0) }
				), axis: .vertical)
				.textFieldStyle(.plain)
				.font(.system(.body, design: .monospaced))
				.onSubmit {
					onSubmit()
				}
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
