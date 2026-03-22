import XCTest
@testable import Braindump

final class DateFormattingTests: XCTestCase {

	private let pacificTZ = TimeZone(identifier: "America/Los_Angeles")!

	private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, _ second: Int, timeZone: TimeZone? = nil) -> Date {
		var calendar = Calendar.current
		calendar.timeZone = timeZone ?? pacificTZ
		return calendar.date(from: DateComponents(
			timeZone: timeZone ?? pacificTZ,
			year: year, month: month, day: day,
			hour: hour, minute: minute, second: second
		))!
	}

	// MARK: - Logical Date

	func testLogicalDateAfterDayStart() {
		let now = date(2026, 3, 21, 14, 30, 0)
		let result = DateFormatting.logicalDate(for: now, dayStartHour: 2, timeZone: pacificTZ)
		XCTAssertEqual(result, "2026-03-21")
	}

	func testLogicalDateBeforeDayStart() {
		let now = date(2026, 3, 22, 1, 30, 0)
		let result = DateFormatting.logicalDate(for: now, dayStartHour: 2, timeZone: pacificTZ)
		XCTAssertEqual(result, "2026-03-21")
	}

	func testLogicalDateExactlyAtDayStart() {
		let now = date(2026, 3, 22, 2, 0, 0)
		let result = DateFormatting.logicalDate(for: now, dayStartHour: 2, timeZone: pacificTZ)
		XCTAssertEqual(result, "2026-03-22")
	}

	func testLogicalDateMidnight() {
		let now = date(2026, 3, 22, 0, 0, 0)
		let result = DateFormatting.logicalDate(for: now, dayStartHour: 2, timeZone: pacificTZ)
		XCTAssertEqual(result, "2026-03-21")
	}

	func testLogicalDateCustomDayStart() {
		let now = date(2026, 3, 22, 4, 30, 0)
		let result = DateFormatting.logicalDate(for: now, dayStartHour: 5, timeZone: pacificTZ)
		XCTAssertEqual(result, "2026-03-21")
	}

	func testLogicalDateDayStartZero() {
		let now = date(2026, 3, 22, 0, 30, 0)
		let result = DateFormatting.logicalDate(for: now, dayStartHour: 0, timeZone: pacificTZ)
		XCTAssertEqual(result, "2026-03-22")
	}

	// MARK: - Entry Timestamp

	func testEntryTimestamp() {
		let now = date(2026, 3, 21, 14, 41, 33)
		let result = DateFormatting.entryTimestamp(from: now, timeZone: pacificTZ)
		XCTAssertEqual(result, "14:41:33")
	}

	func testEntryTimestampMidnight() {
		let now = date(2026, 3, 22, 0, 5, 9)
		let result = DateFormatting.entryTimestamp(from: now, timeZone: pacificTZ)
		XCTAssertEqual(result, "00:05:09")
	}

	// MARK: - Edited Timestamp

	func testEditedTimestamp() {
		let now = date(2026, 3, 21, 14, 42, 7)
		let result = DateFormatting.editedTimestamp(from: now, timeZone: pacificTZ)
		XCTAssertTrue(result.contains("2026-03-21"))
		XCTAssertTrue(result.contains("14:42:07"))
	}

	// MARK: - 12-Hour Conversion

	func testTo12HourPM() {
		XCTAssertEqual(DateFormatting.to12Hour("14:41:33"), "2:41:33 PM")
	}

	func testTo12HourAM() {
		XCTAssertEqual(DateFormatting.to12Hour("09:05:00"), "9:05:00 AM")
	}

	func testTo12HourMidnight() {
		XCTAssertEqual(DateFormatting.to12Hour("00:00:00"), "12:00:00 AM")
	}

	func testTo12HourNoon() {
		XCTAssertEqual(DateFormatting.to12Hour("12:00:00"), "12:00:00 PM")
	}

	func testTo12HourInvalid() {
		XCTAssertEqual(DateFormatting.to12Hour("invalid"), "invalid")
	}

	// MARK: - Display Date

	func testDisplayDate() {
		let result = DateFormatting.displayDate("2026-03-21")
		XCTAssertEqual(result, "March 21, 2026")
	}

	func testDisplayDateInvalid() {
		XCTAssertEqual(DateFormatting.displayDate("not-a-date"), "not-a-date")
	}
}
