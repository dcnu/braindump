import Foundation
import SwiftUI

@Observable
final class AppState {
	var currentDate: String
	var dailyFile: DailyFile?
	var index: [IndexEntry] = []
	var draftContent: String = ""
	var editingEntryID: UUID? = nil
	var isPanelVisible: Bool = false

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
		let dates = index.map(\.date).sorted()
		guard !dates.isEmpty else { return }

		if let currentIndex = dates.firstIndex(of: currentDate) {
			let newIndex = currentIndex + offset
			if newIndex >= 0 && newIndex < dates.count {
				currentDate = dates[newIndex]
				loadCurrentDay()
			}
		} else if offset > 0 {
			if let next = dates.first(where: { $0 > currentDate }) {
				currentDate = next
				loadCurrentDay()
			}
		} else {
			if let prev = dates.last(where: { $0 < currentDate }) {
				currentDate = prev
				loadCurrentDay()
			}
		}
	}

	func navigateToToday() {
		currentDate = DateFormatting.logicalDate(dayStartHour: settings.dayStartHour)
		loadCurrentDay()
	}

	// MARK: - Entry Management

	func createEntry() -> UUID? {
		guard dailyFile?.frontMatter.status != .processed else { return nil }

		let timestamp = DateFormatting.entryTimestamp()
		let entry = Entry(timestamp: timestamp, content: "")

		if dailyFile == nil {
			let now = Date()
			dailyFile = DailyFile(
				frontMatter: FrontMatter(
					created: currentDate,
					edited: DateFormatting.editedTimestamp(from: now)
				),
				entries: [entry]
			)
		} else {
			dailyFile?.entries.append(entry)
		}

		editingEntryID = entry.id
		return entry.id
	}

	func submitEntry() {
		guard let entryID = editingEntryID,
			  var file = dailyFile else { return }

		if let idx = file.entries.firstIndex(where: { $0.id == entryID }) {
			if file.entries[idx].content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
				file.entries.remove(at: idx)
			}
		}

		file.frontMatter.edited = DateFormatting.editedTimestamp()
		dailyFile = file
		editingEntryID = nil

		saveCurrentDay()
	}

	func deleteEntry(id: UUID) {
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
		}
	}

	func updateEntryContent(id: UUID, content: String) {
		guard var file = dailyFile,
			  let idx = file.entries.firstIndex(where: { $0.id == id }) else { return }

		file.entries[idx] = Entry(id: id, timestamp: file.entries[idx].timestamp, content: content)
		dailyFile = file
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

	var isCurrentDayProcessed: Bool {
		dailyFile?.frontMatter.status == .processed
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
