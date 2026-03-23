import XCTest
@testable import Braindump

final class DateParserTests: XCTestCase {
	private let pacificTZ = TimeZone(identifier: "America/Los_Angeles")!

	// MARK: - Suggestions

	func testSuggestionsForYest() {
		let results = DateParser.suggestions(for: "yest")
		XCTAssertTrue(results.contains("yesterday"))
	}

	func testSuggestionsForLast() {
		let results = DateParser.suggestions(for: "last")
		XCTAssertTrue(results.contains("last week"))
		XCTAssertTrue(results.contains("last monday"))
	}

	func testSuggestionsForExactMatch() {
		let results = DateParser.suggestions(for: "today")
		XCTAssertFalse(results.contains("today"))
	}

	func testSuggestionsEmpty() {
		let results = DateParser.suggestions(for: "")
		XCTAssertTrue(results.isEmpty)
	}

	func testSuggestionsNoMatch() {
		let results = DateParser.suggestions(for: "xyz")
		XCTAssertTrue(results.isEmpty)
	}

	// MARK: - Parse

	func testParseToday() {
		let result = DateParser.parse("today", dayStartHour: 2, timeZone: pacificTZ)
		XCTAssertNotNil(result)
	}

	func testParseYesterday() {
		let result = DateParser.parse("yesterday", dayStartHour: 2, timeZone: pacificTZ)
		XCTAssertNotNil(result)
		XCTAssertNotEqual(result, DateParser.parse("today", dayStartHour: 2, timeZone: pacificTZ))
	}

	func testParseExactDate() {
		let result = DateParser.parse("2026-03-21", dayStartHour: 2, timeZone: pacificTZ)
		XCTAssertEqual(result, "2026-03-21")
	}

	func testParseDaysAgo() {
		let result = DateParser.parse("3 days ago", dayStartHour: 2, timeZone: pacificTZ)
		XCTAssertNotNil(result)
	}

	func testParseLastMonday() {
		let result = DateParser.parse("last monday", dayStartHour: 2, timeZone: pacificTZ)
		XCTAssertNotNil(result)
	}

	func testParseInvalid() {
		let result = DateParser.parse("not a date", dayStartHour: 2, timeZone: pacificTZ)
		XCTAssertNil(result)
	}

	func testParseEmpty() {
		let result = DateParser.parse("", dayStartHour: 2, timeZone: pacificTZ)
		XCTAssertNil(result)
	}
}
