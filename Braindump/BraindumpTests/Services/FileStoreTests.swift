import XCTest
@testable import Braindump

final class FileStoreTests: XCTestCase {
	var tempDir: URL!
	var store: FileStore!

	override func setUp() {
		super.setUp()
		tempDir = FileManager.default.temporaryDirectory
			.appendingPathComponent("braindump-test-\(UUID().uuidString)")
		store = FileStore(baseURL: tempDir)
		try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
	}

	override func tearDown() {
		try? FileManager.default.removeItem(at: tempDir)
		super.tearDown()
	}

	func testSaveAndLoad() throws {
		let file = DailyFile(
			frontMatter: FrontMatter(created: "2026-03-21", edited: "2026-03-21T14:00:00-07:00"),
			entries: [Entry(timestamp: "14:00:00", content: "test note")]
		)

		try store.saveDailyFile(file)

		let loaded = try store.loadDailyFile(for: "2026-03-21")
		XCTAssertNotNil(loaded)
		XCTAssertEqual(loaded?.frontMatter.created, "2026-03-21")
		XCTAssertEqual(loaded?.entries.count, 1)
		XCTAssertEqual(loaded?.entries[0].content, "test note")
	}

	func testLoadNonexistent() throws {
		let loaded = try store.loadDailyFile(for: "2099-01-01")
		XCTAssertNil(loaded)
	}

	func testDelete() throws {
		let file = DailyFile(
			frontMatter: FrontMatter(created: "2026-03-21", edited: "2026-03-21T14:00:00-07:00"),
			entries: [Entry(timestamp: "14:00:00", content: "to delete")]
		)

		try store.saveDailyFile(file)
		XCTAssertNotNil(try store.loadDailyFile(for: "2026-03-21"))

		try store.deleteDailyFile(for: "2026-03-21")
		XCTAssertNil(try store.loadDailyFile(for: "2026-03-21"))
	}

	func testDeleteNonexistent() throws {
		XCTAssertNoThrow(try store.deleteDailyFile(for: "2099-01-01"))
	}

	func testListDailyFiles() throws {
		for date in ["2026-03-19", "2026-03-20", "2026-03-21"] {
			let file = DailyFile(
				frontMatter: FrontMatter(created: date, edited: "\(date)T10:00:00-07:00"),
				entries: [Entry(timestamp: "10:00:00", content: "note")]
			)
			try store.saveDailyFile(file)
		}

		let list = try store.listDailyFiles()
		XCTAssertEqual(list, ["2026-03-19", "2026-03-20", "2026-03-21"])
	}

	func testListIgnoresNonDateFiles() throws {
		let file = DailyFile(
			frontMatter: FrontMatter(created: "2026-03-21", edited: "2026-03-21T10:00:00-07:00"),
			entries: []
		)
		try store.saveDailyFile(file)

		// Write a non-date file
		let junkURL = tempDir.appendingPathComponent("index.json")
		try "{}".write(to: junkURL, atomically: true, encoding: .utf8)

		let notMdURL = tempDir.appendingPathComponent("notes.txt")
		try "text".write(to: notMdURL, atomically: true, encoding: .utf8)

		let list = try store.listDailyFiles()
		XCTAssertEqual(list, ["2026-03-21"])
	}

	func testListEmptyDirectory() throws {
		let list = try store.listDailyFiles()
		XCTAssertEqual(list, [])
	}

	func testSaveCreatesDirectory() throws {
		let newDir = tempDir.appendingPathComponent("nested/braindump")
		let nestedStore = FileStore(baseURL: newDir)

		let file = DailyFile(
			frontMatter: FrontMatter(created: "2026-03-21", edited: "2026-03-21T10:00:00-07:00"),
			entries: [Entry(timestamp: "10:00:00", content: "nested test")]
		)

		try nestedStore.saveDailyFile(file)

		let loaded = try nestedStore.loadDailyFile(for: "2026-03-21")
		XCTAssertEqual(loaded?.entries[0].content, "nested test")
	}

	func testOverwriteExistingFile() throws {
		let file1 = DailyFile(
			frontMatter: FrontMatter(created: "2026-03-21", edited: "2026-03-21T10:00:00-07:00"),
			entries: [Entry(timestamp: "10:00:00", content: "original")]
		)
		try store.saveDailyFile(file1)

		var file2 = file1
		file2.entries[0] = Entry(timestamp: "10:00:00", content: "updated")
		file2.frontMatter.edited = "2026-03-21T11:00:00-07:00"
		try store.saveDailyFile(file2)

		let loaded = try store.loadDailyFile(for: "2026-03-21")
		XCTAssertEqual(loaded?.entries[0].content, "updated")
		XCTAssertEqual(loaded?.frontMatter.edited, "2026-03-21T11:00:00-07:00")
	}
}
