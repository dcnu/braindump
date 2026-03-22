import XCTest
@testable import Braindump

final class DailyFileTests: XCTestCase {

	// MARK: - Parsing

	func testParseBasicFile() {
		let markdown = """
		---
		created: 2026-03-21
		edited: 2026-03-21T14:42:07-07:00
		status: active
		---

		## 14:41:33

		candidate has 5 years of experience

		## 14:42:07

		strong knowledge in React and TypeS
		follow up question about state management
		"""

		let file = DailyFile.parse(markdown: markdown)
		XCTAssertNotNil(file)
		XCTAssertEqual(file?.frontMatter.created, "2026-03-21")
		XCTAssertEqual(file?.frontMatter.edited, "2026-03-21T14:42:07-07:00")
		XCTAssertEqual(file?.frontMatter.status, .active)
		XCTAssertEqual(file?.entries.count, 2)
		XCTAssertEqual(file?.entries[0].timestamp, "14:41:33")
		XCTAssertEqual(file?.entries[0].content, "candidate has 5 years of experience")
		XCTAssertEqual(file?.entries[1].timestamp, "14:42:07")
		XCTAssertTrue(file?.entries[1].content.contains("strong knowledge") ?? false)
		XCTAssertTrue(file?.entries[1].content.contains("follow up question") ?? false)
	}

	func testParseProcessedStatus() {
		let markdown = """
		---
		created: 2026-03-20
		edited: 2026-03-21T02:00:00-07:00
		status: processed
		---

		## 10:00:00

		some note
		"""

		let file = DailyFile.parse(markdown: markdown)
		XCTAssertEqual(file?.frontMatter.status, .processed)
	}

	func testParseExtraFrontMatterFields() {
		let markdown = """
		---
		created: 2026-03-21
		edited: 2026-03-21T14:42:07-07:00
		status: active
		processed_at: 2026-03-22T02:00:00-07:00
		agent: summarizer
		tags: meeting, hiring
		---

		## 14:00:00

		test content
		"""

		let file = DailyFile.parse(markdown: markdown)
		XCTAssertEqual(file?.frontMatter.extras["processed_at"], "2026-03-22T02:00:00-07:00")
		XCTAssertEqual(file?.frontMatter.extras["agent"], "summarizer")
		XCTAssertEqual(file?.frontMatter.extras["tags"], "meeting, hiring")
	}

	func testParseFrontMatterOnly() {
		let markdown = """
		---
		created: 2026-03-21
		edited: 2026-03-21T10:00:00-07:00
		status: active
		---
		"""

		let file = DailyFile.parse(markdown: markdown)
		XCTAssertNotNil(file)
		XCTAssertEqual(file?.entries.count, 0)
	}

	func testParseInvalidMarkdown() {
		let file = DailyFile.parse(markdown: "no front matter here")
		XCTAssertNil(file)
	}

	func testParseMissingCreated() {
		let markdown = """
		---
		edited: 2026-03-21T14:42:07-07:00
		status: active
		---
		"""

		let file = DailyFile.parse(markdown: markdown)
		XCTAssertNil(file)
	}

	func testParseEntryWithTaskItems() {
		let markdown = """
		---
		created: 2026-03-21
		edited: 2026-03-21T14:55:00-07:00
		status: active
		---

		## 14:55:00

		- [ ] send follow-up email to candidate
		- [ ] check references
		"""

		let file = DailyFile.parse(markdown: markdown)
		XCTAssertEqual(file?.entries.count, 1)
		XCTAssertTrue(file?.entries[0].content.contains("- [ ] send") ?? false)
		XCTAssertTrue(file?.entries[0].content.contains("- [ ] check") ?? false)
	}

	func testParseEntryWithWikilinks() {
		let markdown = """
		---
		created: 2026-03-21
		edited: 2026-03-21T15:10:44-07:00
		status: active
		---

		## 15:10:44

		[[hiring-pipeline]] might need to adjust criteria
		for senior roles
		"""

		let file = DailyFile.parse(markdown: markdown)
		XCTAssertEqual(file?.entries.count, 1)
		XCTAssertTrue(file?.entries[0].content.contains("[[hiring-pipeline]]") ?? false)
	}

	// MARK: - Serialization

	func testSerializeRoundTrip() {
		let original = """
		---
		created: 2026-03-21
		edited: 2026-03-21T14:42:07-07:00
		status: active
		---

		## 14:41:33

		candidate has 5 years of experience

		## 14:42:07

		strong knowledge in React
		"""

		guard let file = DailyFile.parse(markdown: original) else {
			XCTFail("Failed to parse")
			return
		}

		let serialized = DailyFile.serialize(file)
		guard let reparsed = DailyFile.parse(markdown: serialized) else {
			XCTFail("Failed to reparse")
			return
		}

		XCTAssertEqual(file.frontMatter, reparsed.frontMatter)
		XCTAssertEqual(file.entries.count, reparsed.entries.count)
		for (a, b) in zip(file.entries, reparsed.entries) {
			XCTAssertEqual(a.timestamp, b.timestamp)
			XCTAssertEqual(a.content, b.content)
		}
	}

	func testSerializeExtraFieldsRoundTrip() {
		let frontMatter = FrontMatter(
			created: "2026-03-21",
			edited: "2026-03-21T14:42:07-07:00",
			status: .processed,
			extras: ["agent": "summarizer", "processed_at": "2026-03-22T02:00:00-07:00"]
		)
		let file = DailyFile(
			frontMatter: frontMatter,
			entries: [Entry(timestamp: "14:00:00", content: "test")]
		)

		let serialized = DailyFile.serialize(file)
		let reparsed = DailyFile.parse(markdown: serialized)

		XCTAssertEqual(reparsed?.frontMatter.extras["agent"], "summarizer")
		XCTAssertEqual(reparsed?.frontMatter.extras["processed_at"], "2026-03-22T02:00:00-07:00")
	}

	func testSerializeEmptyContent() {
		let file = DailyFile(
			frontMatter: FrontMatter(created: "2026-03-21", edited: "2026-03-21T10:00:00-07:00"),
			entries: [Entry(timestamp: "10:00:00", content: "")]
		)

		let serialized = DailyFile.serialize(file)
		XCTAssertTrue(serialized.contains("## 10:00:00"))
		XCTAssertNotNil(DailyFile.parse(markdown: serialized))
	}

	func testSerializeMultipleEntries() {
		let file = DailyFile(
			frontMatter: FrontMatter(created: "2026-03-21", edited: "2026-03-21T15:00:00-07:00"),
			entries: [
				Entry(timestamp: "14:00:00", content: "first entry"),
				Entry(timestamp: "14:30:00", content: "second entry\nwith multiple lines"),
				Entry(timestamp: "15:00:00", content: "- [ ] task item"),
			]
		)

		let serialized = DailyFile.serialize(file)
		let reparsed = DailyFile.parse(markdown: serialized)

		XCTAssertEqual(reparsed?.entries.count, 3)
		XCTAssertEqual(reparsed?.entries[0].content, "first entry")
		XCTAssertEqual(reparsed?.entries[1].content, "second entry\nwith multiple lines")
		XCTAssertEqual(reparsed?.entries[2].content, "- [ ] task item")
	}
}
