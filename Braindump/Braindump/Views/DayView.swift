import SwiftUI

struct DayView: View {
	@Bindable var appState: AppState

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			dayHeader

			if appState.dailyFile != nil {
				ForEach(appState.displayEntries()) { entry in
					EntryRow(
						entry: entry,
						displayTimestamp: appState.displayTimestamp(entry.timestamp),
						isProcessed: appState.isCurrentDayProcessed,
						isEditing: appState.editingEntryID == entry.id,
						editContent: $appState.editingContent,
						onTap: {
							if !appState.isCurrentDayProcessed {
								appState.editingEntryID = entry.id
							}
						},
						onSubmit: {
							appState.submitEntry()
						},
						onDelete: {
							appState.deleteEntry(id: entry.id)
						}
					)
				}
			} else {
				Text("No entries")
					.font(.system(.body, design: .monospaced))
					.foregroundStyle(.tertiary)
					.frame(maxWidth: .infinity, alignment: .center)
					.padding(.top, 20)
			}
		}
	}

	private var dayHeader: some View {
		HStack(spacing: 6) {
			Image(systemName: "clock")
				.foregroundStyle(.secondary)
				.font(.system(.caption))

			Text(DateFormatting.displayDate(appState.currentDate))
				.font(.system(.headline, design: .monospaced))

			if appState.isCurrentDayProcessed {
				Image(systemName: "lock.fill")
					.foregroundStyle(.secondary)
					.font(.system(.caption))
			}

			Spacer()
		}
	}
}
