import XCTest
@testable import Braindump

final class IndexManagerTests: XCTestCase {
	var tempDir: URL!
	var store: FileStore!
	var indexManager: IndexManager!

	override func setUp() {
		super.setUp()
		tempDir = FileManager.default.temporaryDirectory
			.appendingPathComponent("braindump-index-test-\(UUID().uuidString)")
		try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
		store = FileStore(baseURL: tempDir)
		indexManager = IndexManager(store: store)
	}

	override func tearDown() {
		try? FileManager.default.removeItem(at: tempDir)
		super.tearDown()
	}

	func testRebuildEmptyDirectory() throws {
		let index = try indexManager.rebuildIndex()
		XCTAssertEqual(index.count, 0)
	}

	func testRebuildWithFiles() throws {
		try createTestFile(date: "2026-03-20", entries: [("10:00:00", "morning note")])
		try createTestFile(date: "2026-03-21", entries: [
			("14:00:00", "first"),
			("15:00:00", "second"),
		])

		let index = try indexManager.rebuildIndex()
		XCTAssertEqual(index.count, 2)

		let march20 = index.first { $0.date == "2026-03-20" }
		XCTAssertNotNil(march20)
		XCTAssertEqual(march20?.entryCount, 1)
		XCTAssertEqual(march20?.lastEntryTime, "10:00:00")
		XCTAssertEqual(march20?.status, "active")

		let march21 = index.first { $0.date == "2026-03-21" }
		XCTAssertNotNil(march21)
		XCTAssertEqual(march21?.entryCount, 2)
		XCTAssertEqual(march21?.lastEntryTime, "15:00:00")
	}

	func testRebuildProcessedFile() throws {
		let file = DailyFile(
			frontMatter: FrontMatter(
				created: "2026-03-19",
				edited: "2026-03-20T02:00:00-07:00",
				status: .processed
			),
			entries: [Entry(timestamp: "09:00:00", content: "old note")]
		)
		try store.saveDailyFile(file)

		let index = try indexManager.rebuildIndex()
		XCTAssertEqual(index.first?.status, "processed")
	}

	func testWriteAndReadIndex() throws {
		let entries = [
			IndexEntry(date: "2026-03-21", filePath: "braindump/2026-03-21.md", status: "active", entryCount: 2, lastEntryTime: "15:00:00"),
			IndexEntry(date: "2026-03-20", filePath: "braindump/2026-03-20.md", status: "processed", entryCount: 1, lastEntryTime: "10:00:00"),
		]

		let indexURL = tempDir.appendingPathComponent("index.json")
		try indexManager.writeIndex(entries, to: indexURL)

		let read = try indexManager.readIndex(from: indexURL)
		XCTAssertEqual(read.count, 2)
		XCTAssertEqual(read[0].date, "2026-03-21")
		XCTAssertEqual(read[1].status, "processed")
	}

	func testReadNonexistentIndex() throws {
		let indexURL = tempDir.appendingPathComponent("nonexistent.json")
		let read = try indexManager.readIndex(from: indexURL)
		XCTAssertEqual(read.count, 0)
	}

	func testReconcileDetectsNewFile() throws {
		try createTestFile(date: "2026-03-20", entries: [("10:00:00", "existing")])
		let initial = try indexManager.rebuildIndex()
		XCTAssertEqual(initial.count, 1)

		try createTestFile(date: "2026-03-21", entries: [("14:00:00", "new file")])
		let reconciled = try indexManager.reconcile(current: initial)
		XCTAssertEqual(reconciled.count, 2)
	}

	func testReconcileDetectsDeletedFile() throws {
		try createTestFile(date: "2026-03-20", entries: [("10:00:00", "to delete")])
		try createTestFile(date: "2026-03-21", entries: [("14:00:00", "keep")])
		let initial = try indexManager.rebuildIndex()
		XCTAssertEqual(initial.count, 2)

		try store.deleteDailyFile(for: "2026-03-20")
		let reconciled = try indexManager.reconcile(current: initial)
		XCTAssertEqual(reconciled.count, 1)
		XCTAssertEqual(reconciled[0].date, "2026-03-21")
	}

	func testIndexEntryFilePath() throws {
		try createTestFile(date: "2026-03-21", entries: [("14:00:00", "test")])
		let index = try indexManager.rebuildIndex()
		XCTAssertEqual(index[0].filePath, "braindump/2026-03-21.md")
	}

	// MARK: - Helpers

	private func createTestFile(date: String, entries: [(String, String)]) throws {
		let file = DailyFile(
			frontMatter: FrontMatter(created: date, edited: "\(date)T10:00:00-07:00"),
			entries: entries.map { Entry(timestamp: $0.0, content: $0.1) }
		)
		try store.saveDailyFile(file)
	}
}
