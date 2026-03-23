import Foundation
import SwiftUI

@Observable
final class AppState {
	var currentDate: String
	var dailyFile: DailyFile?
	var index: [IndexEntry] = []

	// Draft state
	var draftContent: String = ""
	var isDrafting: Bool = false

	// Edit state
	var editingEntryID: UUID? = nil
	var editingContent: String = ""

	var isPanelVisible: Bool = false
	var showingShortcuts: Bool = false
	var showingDateJump: Bool = false
	var dateJumpQuery: String = ""

	let settings: AppSettings
	private(set) var fileStore: FileStore
	private(set) var indexManager: IndexManager
	private var fileWatcher: FileWatcher?
	private var reconciliationTimer: Timer?

	init(settings: AppSettings = AppSettings()) {
		self.settings = settings
		self.currentDate = DateFormatting.logicalDate(dayStartHour: settings.dayStartHour)

		let store = FileStore(baseURL: settings.braindumpURL)
		self.fileStore = store
		self.indexManager = IndexManager(store: store)

		setup()
	}

	// MARK: - Computed

	var isToday: Bool {
		currentDate == DateFormatting.logicalDate(dayStartHour: settings.dayStartHour)
	}

	var isReadOnly: Bool {
		!isToday || isCurrentDayProcessed
	}

	var isCurrentDayProcessed: Bool {
		dailyFile?.frontMatter.status == .processed
	}

	// MARK: - Setup

	private func setup() {
		try? fileStore.ensureDirectoryExists()
		loadIndex()
		loadCurrentDay()
		startFileWatcher()
		startReconciliationTimer()
	}

	// MARK: - Navigation

	func navigateDay(offset: Int) {
		// Use filesystem directly — no stale index dependency
		guard let dates = try? fileStore.listDailyFiles(), !dates.isEmpty else { return }

		if let idx = dates.firstIndex(of: currentDate) {
			let newIdx = idx + offset
			if newIdx >= 0 && newIdx < dates.count {
				currentDate = dates[newIdx]
				loadCurrentDay()
			}
		} else if offset < 0 {
			if let prev = dates.last(where: { $0 < currentDate }) {
				currentDate = prev
				loadCurrentDay()
			}
		} else {
			if let next = dates.first(where: { $0 > currentDate }) {
				currentDate = next
				loadCurrentDay()
			}
		}
	}

	func navigateToToday() {
		currentDate = DateFormatting.logicalDate(dayStartHour: settings.dayStartHour)
		loadCurrentDay()
	}

	func jumpToDate(_ dateString: String) {
		currentDate = dateString
		loadCurrentDay()
		showingDateJump = false
		dateJumpQuery = ""
	}

	// MARK: - Draft (new entry) — always targets today

	func startDraft() {
		if !isToday {
			navigateToToday()
		}
		guard !isCurrentDayProcessed else { return }
		isDrafting = true
		draftContent = ""
	}

	func submitDraft() {
		let content = draftContent.trimmingCharacters(in: .whitespacesAndNewlines)
		isDrafting = false
		draftContent = ""

		guard !content.isEmpty else { return }

		// Ensure we're on today
		if !isToday {
			navigateToToday()
		}

		let now = Date()
		let timestamp = DateFormatting.entryTimestamp(from: now)
		let entry = Entry(timestamp: timestamp, content: content)

		if dailyFile == nil {
			dailyFile = DailyFile(
				frontMatter: FrontMatter(
					created: currentDate,
					edited: DateFormatting.editedTimestamp(from: now)
				),
				entries: [entry]
			)
		} else {
			dailyFile?.entries.append(entry)
			dailyFile?.frontMatter.edited = DateFormatting.editedTimestamp(from: now)
		}

		saveCurrentDay()
	}

	func cancelDraft() {
		isDrafting = false
		draftContent = ""
	}

	// MARK: - Edit (existing entry) — only today

	func startEditing(id: UUID) {
		guard isToday, !isCurrentDayProcessed,
			  let entry = dailyFile?.entries.first(where: { $0.id == id }) else { return }
		editingEntryID = id
		editingContent = entry.content
	}

	func submitEdit() {
		guard isToday,
			  let entryID = editingEntryID,
			  var file = dailyFile,
			  let idx = file.entries.firstIndex(where: { $0.id == entryID }) else {
			editingEntryID = nil
			editingContent = ""
			return
		}

		let content = editingContent.trimmingCharacters(in: .whitespacesAndNewlines)

		if content.isEmpty {
			file.entries.remove(at: idx)
		} else {
			file.entries[idx] = Entry(
				id: entryID,
				timestamp: file.entries[idx].timestamp,
				content: content
			)
		}

		file.frontMatter.edited = DateFormatting.editedTimestamp()
		dailyFile = file
		editingEntryID = nil
		editingContent = ""

		saveCurrentDay()
	}

	func cancelEdit() {
		editingEntryID = nil
		editingContent = ""
	}

	func deleteEntry(id: UUID) {
		guard isToday else { return }
		guard var file = dailyFile else { return }
		file.entries.removeAll { $0.id == id }

		if file.entries.isEmpty {
			try? fileStore.deleteDailyFile(for: currentDate)
			dailyFile = nil
		} else {
			file.frontMatter.edited = DateFormatting.editedTimestamp()
			dailyFile = file
			saveCurrentDay()
		}

		if editingEntryID == id {
			editingEntryID = nil
			editingContent = ""
		}
	}

	// MARK: - Display Helpers

	func displayEntries() -> [Entry] {
		guard let entries = dailyFile?.entries else { return [] }
		switch settings.entryOrder {
		case .reverseChronological:
			return entries.reversed()
		case .chronological:
			return entries
		}
	}

	func displayTimestamp(_ timestamp: String) -> String {
		switch settings.timeFormat {
		case .h24:
			return timestamp
		case .h12:
			return DateFormatting.to12Hour(timestamp)
		}
	}

	// MARK: - File Operations

	func loadCurrentDay() {
		dailyFile = try? fileStore.loadDailyFile(for: currentDate)
	}

	private func saveCurrentDay() {
		guard let file = dailyFile else { return }
		try? fileStore.saveDailyFile(file)
		loadIndex()
	}

	private func loadIndex() {
		index = (try? indexManager.rebuildIndex()) ?? []
	}

	// MARK: - File Watching

	private func startFileWatcher() {
		fileWatcher = FileWatcher(directoryURL: settings.braindumpURL) { [weak self] in
			self?.handleFileChange()
		}
		fileWatcher?.start()
	}

	func handleFileChange() {
		loadIndex()
		loadCurrentDay()
	}

	private func startReconciliationTimer() {
		reconciliationTimer = Timer.scheduledTimer(
			withTimeInterval: Constants.reconciliationInterval,
			repeats: true
		) { [weak self] _ in
			self?.handleFileChange()
		}
	}

	// MARK: - Reconfiguration

	func reconfigure() {
		fileWatcher?.stop()
		fileStore = FileStore(baseURL: settings.braindumpURL)
		indexManager = IndexManager(store: fileStore)
		try? fileStore.ensureDirectoryExists()
		loadIndex()
		navigateToToday()
		startFileWatcher()
	}
}
