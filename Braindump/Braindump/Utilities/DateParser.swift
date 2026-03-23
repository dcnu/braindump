import Foundation

enum DateParser {
	/// Parse a natural language date string into yyyy-MM-dd format.
	/// Returns nil if the input can't be parsed.
	static func parse(_ input: String, relativeTo now: Date = Date(), dayStartHour: Int = 2, timeZone: TimeZone = .current) -> String? {
		let text = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
		guard !text.isEmpty else { return nil }

		var calendar = Calendar.current
		calendar.timeZone = timeZone

		let today = DateFormatting.logicalDate(for: now, dayStartHour: dayStartHour, timeZone: timeZone)

		// Keywords
		if text == "today" || text == "now" {
			return today
		}

		if text == "yesterday" {
			if let date = calendar.date(byAdding: .day, value: -1, to: dateFromString(today, calendar: calendar)!) {
				return formatDate(date, timeZone: timeZone)
			}
		}

		if text == "tomorrow" {
			if let date = calendar.date(byAdding: .day, value: 1, to: dateFromString(today, calendar: calendar)!) {
				return formatDate(date, timeZone: timeZone)
			}
		}

		if text == "last week" {
			if let date = calendar.date(byAdding: .day, value: -7, to: dateFromString(today, calendar: calendar)!) {
				return formatDate(date, timeZone: timeZone)
			}
		}

		// N days ago
		if let match = text.wholeMatch(of: /(\d+)\s+days?\s+ago/) {
			if let n = Int(match.1),
			   let date = calendar.date(byAdding: .day, value: -n, to: dateFromString(today, calendar: calendar)!) {
				return formatDate(date, timeZone: timeZone)
			}
		}

		// N weeks ago
		if let match = text.wholeMatch(of: /(\d+)\s+weeks?\s+ago/) {
			if let n = Int(match.1),
			   let date = calendar.date(byAdding: .day, value: -n * 7, to: dateFromString(today, calendar: calendar)!) {
				return formatDate(date, timeZone: timeZone)
			}
		}

		// "last monday", "last friday", etc.
		if let match = text.wholeMatch(of: /last\s+(\w+)/) {
			if let weekday = parseWeekday(String(match.1)) {
				return findPreviousWeekday(weekday, from: dateFromString(today, calendar: calendar)!, calendar: calendar, timeZone: timeZone)
			}
		}

		// "monday", "this monday", etc.
		if let match = text.wholeMatch(of: /(this\s+)?(\w+)/) {
			if let weekday = parseWeekday(String(match.2)) {
				return findPreviousWeekday(weekday, from: dateFromString(today, calendar: calendar)!, calendar: calendar, timeZone: timeZone)
			}
		}

		// Exact date formats
		let formats = [
			"yyyy-MM-dd",
			"MMMM d, yyyy",
			"MMMM d yyyy",
			"MMMM d",
			"MMM d, yyyy",
			"MMM d yyyy",
			"MMM d",
			"M/d/yyyy",
			"M/d",
		]

		for format in formats {
			let formatter = DateFormatter()
			formatter.locale = Locale(identifier: "en_US")
			formatter.timeZone = timeZone
			formatter.dateFormat = format

			if let date = formatter.date(from: input.trimmingCharacters(in: .whitespacesAndNewlines)) {
				var result = date
				// For formats without year, default to current year
				if !format.contains("y") {
					let year = calendar.component(.year, from: now)
					var components = calendar.dateComponents([.month, .day], from: date)
					components.year = year
					if let adjusted = calendar.date(from: components) {
						result = adjusted
					}
				}
				return formatDate(result, timeZone: timeZone)
			}
		}

		return nil
	}

	// MARK: - Private

	private static func parseWeekday(_ name: String) -> Int? {
		let days: [String: Int] = [
			"sunday": 1, "sun": 1,
			"monday": 2, "mon": 2,
			"tuesday": 3, "tue": 3, "tues": 3,
			"wednesday": 4, "wed": 4,
			"thursday": 5, "thu": 5, "thurs": 5,
			"friday": 6, "fri": 6,
			"saturday": 7, "sat": 7,
		]
		return days[name.lowercased()]
	}

	private static func findPreviousWeekday(_ weekday: Int, from date: Date, calendar: Calendar, timeZone: TimeZone) -> String? {
		var current = date
		for _ in 1...7 {
			current = calendar.date(byAdding: .day, value: -1, to: current)!
			if calendar.component(.weekday, from: current) == weekday {
				return formatDate(current, timeZone: timeZone)
			}
		}
		return nil
	}

	private static func dateFromString(_ dateString: String, calendar: Calendar) -> Date? {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd"
		formatter.timeZone = calendar.timeZone
		return formatter.date(from: dateString)
	}

	private static func formatDate(_ date: Date, timeZone: TimeZone) -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd"
		formatter.timeZone = timeZone
		return formatter.string(from: date)
	}
}
