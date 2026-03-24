import SwiftUI

struct DayView: View {
	@Bindable var appState: AppState

	private var fontColor: Color {
		Color(hex: appState.settings.fontColorHex)
	}

	private var timestampColor: Color {
		fontColor.opacity(0.5)
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			dayHeader

			// Draft entry (inline, only on today)
			if appState.isDrafting {
				HStack(alignment: .top, spacing: 12) {
					Text("--:--:--")
						.font(.system(.caption, design: .monospaced))
						.foregroundStyle(timestampColor.opacity(0.5))
						.frame(width: 70, alignment: .leading)

					AutoClosingTextEditor(
						text: $appState.draftContent,
						onSubmit: { appState.submitDraft() },
						autoCorrect: appState.settings.autoCorrect
					)
					.frame(minHeight: 24, maxHeight: 200)
					.onChange(of: appState.draftContent) { oldValue, newValue in
						if appState.settings.enterSubmits && newValue.hasSuffix("\n") && !newValue.hasSuffix("\n\n") {
							let trimmed = newValue.trimmingCharacters(in: .newlines)
							if !trimmed.isEmpty && oldValue == trimmed {
								appState.draftContent = trimmed
								appState.submitDraft()
							}
						}
					}
				}
				.padding(.vertical, 4)
			}

			// Existing entries
			if appState.dailyFile != nil {
				ForEach(appState.displayEntries()) { entry in
					let isSelected = appState.selectedEntryID == entry.id
					EntryRow(
						entry: entry,
						displayTimestamp: appState.displayTimestamp(entry.timestamp),
						isProcessed: appState.isReadOnly,
						isEditing: appState.editingEntryID == entry.id,
						isSelected: isSelected,
						editContent: $appState.editingContent,
						autoCorrect: appState.settings.autoCorrect,
						fontColor: fontColor,
						timestampColor: timestampColor,
						onTap: {
							appState.selectedEntryID = entry.id
							appState.startEditing(id: entry.id)
						},
						onSubmit: {
							appState.submitEdit()
						},
						onDelete: {
							appState.deleteEntry(id: entry.id)
						}
					)
				}
			}

			// Empty state
			if !appState.isDrafting && appState.dailyFile == nil {
				if appState.isToday {
					Text("Press CMD+N to add an entry")
						.font(.system(.body, design: .monospaced))
						.foregroundStyle(timestampColor)
						.frame(maxWidth: .infinity, alignment: .center)
						.padding(.top, 20)
				} else {
					Text("No entries on this day")
						.font(.system(.body, design: .monospaced))
						.foregroundStyle(timestampColor)
						.frame(maxWidth: .infinity, alignment: .center)
						.padding(.top, 20)
				}
			}
		}
	}

	private var dayHeader: some View {
		HStack(spacing: 6) {
			Image(systemName: "clock")
				.foregroundStyle(timestampColor)
				.font(.system(.caption))

			Text(DateFormatting.displayDate(appState.currentDate))
				.font(.system(.headline, design: .monospaced))
				.foregroundStyle(Color(hex: appState.settings.headerColorHex))

			if appState.isToday {
				Text("Today")
					.font(.system(.caption, design: .monospaced))
					.foregroundStyle(.blue)
			}

			if appState.isReadOnly && !appState.isToday {
				Image(systemName: "lock.fill")
					.foregroundStyle(timestampColor)
					.font(.system(.caption))
			}

			if appState.isCurrentDayProcessed {
				Image(systemName: "checkmark.circle.fill")
					.foregroundStyle(.green)
					.font(.system(.caption))
			}

			Spacer()
		}
	}
}
