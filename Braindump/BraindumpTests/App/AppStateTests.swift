import XCTest
@testable import Braindump

final class AppStateTests: XCTestCase {
	var tempDir: URL!
	var settings: AppSettings!
	var appState: AppState!

	override func setUp() {
		super.setUp()
		tempDir = FileManager.default.temporaryDirectory
			.appendingPathComponent("braindump-appstate-test-\(UUID().uuidString)")
		try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

		settings = AppSettings()
		settings.vaultPath = tempDir.path
		appState = AppState(settings: settings)
	}

	override func tearDown() {
		try? FileManager.default.removeItem(at: tempDir)
		super.tearDown()
	}

	// MARK: - isToday

	func testIsTodayOnInit() {
		XCTAssertTrue(appState.isToday)
	}

	func testIsNotTodayAfterNavigatingBack() {
		// Create a file for yesterday so we can navigate to it
		let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd"
		let yesterdayStr = formatter.string(from: yesterday)

		let file = DailyFile(
			frontMatter: FrontMatter(created: yesterdayStr, edited: "\(yesterdayStr)T10:00:00-07:00"),
			entries: [Entry(timestamp: "10:00:00", content: "old note")]
		)
		try? appState.fileStore.saveDailyFile(file)

		appState.navigateDay(offset: -1)
		XCTAssertFalse(appState.isToday)
		XCTAssertTrue(appState.isReadOnly)
	}

	// MARK: - Draft always targets today

	func testStartDraftNavigatesToToday() {
		let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd"
		let yesterdayStr = formatter.string(from: yesterday)

		let file = DailyFile(
			frontMatter: FrontMatter(created: yesterdayStr, edited: "\(yesterdayStr)T10:00:00-07:00"),
			entries: [Entry(timestamp: "10:00:00", content: "old")]
		)
		try? appState.fileStore.saveDailyFile(file)

		appState.navigateDay(offset: -1)
		XCTAssertFalse(appState.isToday)

		appState.startDraft()
		XCTAssertTrue(appState.isToday)
		XCTAssertTrue(appState.isDrafting)
	}

	// MARK: - Submit draft

	func testSubmitDraftCreatesEntry() {
		appState.startDraft()
		appState.draftContent = "test note"
		appState.submitDraft()

		XCTAssertFalse(appState.isDrafting)
		XCTAssertEqual(appState.dailyFile?.entries.count, 1)
		XCTAssertEqual(appState.dailyFile?.entries.first?.content, "Test note") // auto-capitalize
	}

	func testSubmitEmptyDraftCreatesNoEntry() {
		appState.startDraft()
		appState.draftContent = "   "
		appState.submitDraft()

		XCTAssertNil(appState.dailyFile)
	}

	func testSubmitDraftAutoCapitalizes() {
		settings.autoCapitalize = true
		appState.startDraft()
		appState.draftContent = "hello world"
		appState.submitDraft()

		XCTAssertEqual(appState.dailyFile?.entries.first?.content, "Hello world")
	}

	func testSubmitDraftNoAutoCapitalizeWhenDisabled() {
		settings.autoCapitalize = false
		appState.startDraft()
		appState.draftContent = "hello world"
		appState.submitDraft()

		XCTAssertEqual(appState.dailyFile?.entries.first?.content, "hello world")
	}

	// MARK: - Edit gated on isToday

	func testCannotEditPastDay() {
		let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd"
		let yesterdayStr = formatter.string(from: yesterday)

		let entry = Entry(timestamp: "10:00:00", content: "old note")
		let file = DailyFile(
			frontMatter: FrontMatter(created: yesterdayStr, edited: "\(yesterdayStr)T10:00:00-07:00"),
			entries: [entry]
		)
		try? appState.fileStore.saveDailyFile(file)

		appState.navigateDay(offset: -1)
		appState.startEditing(id: entry.id)

		XCTAssertNil(appState.editingEntryID)
	}

	func testCanEditToday() {
		appState.startDraft()
		appState.draftContent = "editable"
		appState.submitDraft()

		guard let entryID = appState.dailyFile?.entries.first?.id else {
			XCTFail("No entry created")
			return
		}

		appState.startEditing(id: entryID)
		XCTAssertEqual(appState.editingEntryID, entryID)
		XCTAssertEqual(appState.editingContent, "Editable")
	}

	// MARK: - Delete gated on isToday

	func testCannotDeleteOnPastDay() {
		let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd"
		let yesterdayStr = formatter.string(from: yesterday)

		let entry = Entry(timestamp: "10:00:00", content: "keep this")
		let file = DailyFile(
			frontMatter: FrontMatter(created: yesterdayStr, edited: "\(yesterdayStr)T10:00:00-07:00"),
			entries: [entry]
		)
		try? appState.fileStore.saveDailyFile(file)

		appState.navigateDay(offset: -1)
		appState.deleteEntry(id: entry.id)

		// Entry should still exist
		appState.loadCurrentDay()
		XCTAssertEqual(appState.dailyFile?.entries.count, 1)
	}

	// MARK: - Navigation uses filesystem

	func testNavigateDayUsesFilesystem() {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd"

		for daysAgo in [1, 3, 5] {
			let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
			let dateStr = formatter.string(from: date)
			let file = DailyFile(
				frontMatter: FrontMatter(created: dateStr, edited: "\(dateStr)T10:00:00-07:00"),
				entries: [Entry(timestamp: "10:00:00", content: "note")]
			)
			try? appState.fileStore.saveDailyFile(file)
		}

		// Navigate back — should skip days without files
		appState.navigateDay(offset: -1)
		let day1 = formatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
		XCTAssertEqual(appState.currentDate, day1)

		appState.navigateDay(offset: -1)
		let day3 = formatter.string(from: Calendar.current.date(byAdding: .day, value: -3, to: Date())!)
		XCTAssertEqual(appState.currentDate, day3)
	}

	// MARK: - Entry selection

	func testSelectEntryDown() {
		appState.startDraft()
		appState.draftContent = "first"
		appState.submitDraft()

		appState.startDraft()
		appState.draftContent = "second"
		appState.submitDraft()

		XCTAssertNil(appState.selectedEntryID)

		appState.selectEntry(offset: 1)
		XCTAssertNotNil(appState.selectedEntryID)
	}

	// MARK: - Math evaluation on submit

	func testMathEvaluationOnSubmit() {
		appState.startDraft()
		appState.draftContent = "math\nx = 10\nx * 5 ="
		appState.submitDraft()

		let content = appState.dailyFile?.entries.first?.content ?? ""
		XCTAssertTrue(content.contains("50"), "Expected math result in: \(content)")
	}

	// MARK: - hasNotesForDate

	func testHasNotesForDate() {
		XCTAssertFalse(appState.hasNotesForDate("2020-01-01"))

		appState.startDraft()
		appState.draftContent = "test"
		appState.submitDraft()

		XCTAssertTrue(appState.hasNotesForDate(appState.currentDate))
	}

	// MARK: - File persistence

	func testEntryPersistsToDisk() {
		appState.startDraft()
		appState.draftContent = "persistent note"
		appState.submitDraft()

		// Reload from disk
		let loaded = try? appState.fileStore.loadDailyFile(for: appState.currentDate)
		XCTAssertEqual(loaded?.entries.count, 1)
		XCTAssertEqual(loaded?.entries.first?.content, "Persistent note")
	}

	func testDeleteLastEntryRemovesFile() {
		appState.startDraft()
		appState.draftContent = "only entry"
		appState.submitDraft()

		guard let entryID = appState.dailyFile?.entries.first?.id else {
			XCTFail("No entry")
			return
		}

		appState.deleteEntry(id: entryID)
		XCTAssertNil(appState.dailyFile)

		let loaded = try? appState.fileStore.loadDailyFile(for: appState.currentDate)
		XCTAssertNil(loaded)
	}
}
