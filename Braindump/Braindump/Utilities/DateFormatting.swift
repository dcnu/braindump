import Foundation

enum DateFormatting {
	/// Returns the logical date string (yyyy-MM-dd) for the given time.
	/// If the current hour is before `dayStartHour`, the previous calendar date is used.
	static func logicalDate(for now: Date = Date(), dayStartHour: Int = Constants.defaultDayStartHour, timeZone: TimeZone = .current) -> String {
		var calendar = Calendar.current
		calendar.timeZone = timeZone

		let hour = calendar.component(.hour, from: now)
		let date: Date
		if hour < dayStartHour {
			date = calendar.date(byAdding: .day, value: -1, to: now) ?? now
		} else {
			date = now
		}

		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd"
		formatter.timeZone = timeZone
		return formatter.string(from: date)
	}

	/// Returns HH:mm:ss in local time zone for entry headings.
	static func entryTimestamp(from now: Date = Date(), timeZone: TimeZone = .current) -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = "HH:mm:ss"
		formatter.timeZone = timeZone
		return formatter.string(from: now)
	}

	/// Returns ISO 8601 with local offset for front-matter `edited` field.
	static func editedTimestamp(from now: Date = Date(), timeZone: TimeZone = .current) -> String {
		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [.withInternetDateTime]
		formatter.timeZone = timeZone
		return formatter.string(from: now)
	}

	/// Converts a 24h timestamp (HH:mm:ss) to 12h format (h:mm:ss a).
	static func to12Hour(_ timestamp: String) -> String {
		let inputFormatter = DateFormatter()
		inputFormatter.dateFormat = "HH:mm:ss"

		guard let date = inputFormatter.date(from: timestamp) else { return timestamp }

		let outputFormatter = DateFormatter()
		outputFormatter.dateFormat = "h:mm:ss a"
		return outputFormatter.string(from: date)
	}

	/// Formats a date string (yyyy-MM-dd) for display (e.g., "March 21, 2026").
	static func displayDate(_ dateString: String) -> String {
		let inputFormatter = DateFormatter()
		inputFormatter.dateFormat = "yyyy-MM-dd"

		guard let date = inputFormatter.date(from: dateString) else { return dateString }

		let outputFormatter = DateFormatter()
		outputFormatter.dateFormat = "MMMM d, yyyy"
		return outputFormatter.string(from: date)
	}
}
