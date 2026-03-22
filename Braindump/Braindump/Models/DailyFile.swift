import Foundation

enum DayStatus: String, Codable, Equatable {
	case active
	case processed
}

struct FrontMatter: Equatable {
	var created: String
	var edited: String
	var status: DayStatus
	var extras: [String: String]

	init(created: String, edited: String, status: DayStatus = .active, extras: [String: String] = [:]) {
		self.created = created
		self.edited = edited
		self.status = status
		self.extras = extras
	}
}

struct Entry: Identifiable, Equatable {
	let id: UUID
	var timestamp: String
	var content: String

	init(id: UUID = UUID(), timestamp: String, content: String) {
		self.id = id
		self.timestamp = timestamp
		self.content = content
	}
}

struct DailyFile: Identifiable, Equatable {
	var id: String { frontMatter.created }
	var frontMatter: FrontMatter
	var entries: [Entry]

	init(frontMatter: FrontMatter, entries: [Entry] = []) {
		self.frontMatter = frontMatter
		self.entries = entries
	}

	// MARK: - Parsing

	static func parse(markdown: String) -> DailyFile? {
		let lines = markdown.components(separatedBy: "\n")

		guard let frontMatter = parseFrontMatter(lines: lines) else { return nil }

		let bodyStartIndex = findBodyStart(lines: lines)
		let bodyLines = Array(lines[bodyStartIndex...])
		let entries = parseEntries(lines: bodyLines)

		return DailyFile(frontMatter: frontMatter, entries: entries)
	}

	static func serialize(_ file: DailyFile) -> String {
		var result = "---\n"
		result += "created: \(file.frontMatter.created)\n"
		result += "edited: \(file.frontMatter.edited)\n"
		result += "status: \(file.frontMatter.status.rawValue)\n"

		for (key, value) in file.frontMatter.extras.sorted(by: { $0.key < $1.key }) {
			result += "\(key): \(value)\n"
		}

		result += "---\n"

		for (index, entry) in file.entries.enumerated() {
			if index > 0 || true {
				result += "\n"
			}
			result += "## \(entry.timestamp)\n"
			if !entry.content.isEmpty {
				result += "\n\(entry.content)\n"
			}
		}

		return result
	}

	// MARK: - Private Parsing Helpers

	private static func parseFrontMatter(lines: [String]) -> FrontMatter? {
		guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else { return nil }

		var created = ""
		var edited = ""
		var status: DayStatus = .active
		var extras: [String: String] = [:]
		let knownKeys: Set<String> = ["created", "edited", "status"]

		for i in 1..<lines.count {
			let line = lines[i].trimmingCharacters(in: .whitespaces)
			if line == "---" { break }

			guard let colonIndex = line.firstIndex(of: ":") else { continue }
			let key = String(line[line.startIndex..<colonIndex]).trimmingCharacters(in: .whitespaces)
			let value = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)

			switch key {
			case "created":
				created = value
			case "edited":
				edited = value
			case "status":
				status = DayStatus(rawValue: value) ?? .active
			default:
				if !knownKeys.contains(key) {
					extras[key] = value
				}
			}
		}

		guard !created.isEmpty else { return nil }

		return FrontMatter(created: created, edited: edited, status: status, extras: extras)
	}

	private static func findBodyStart(lines: [String]) -> Int {
		var delimiterCount = 0
		for (index, line) in lines.enumerated() {
			if line.trimmingCharacters(in: .whitespaces) == "---" {
				delimiterCount += 1
				if delimiterCount == 2 {
					return index + 1
				}
			}
		}
		return lines.count
	}

	private static let timestampPattern = try! NSRegularExpression(pattern: #"^## (\d{2}:\d{2}:\d{2})$"#)

	private static func parseEntries(lines: [String]) -> [Entry] {
		var entries: [Entry] = []
		var currentTimestamp: String?
		var currentContentLines: [String] = []

		for line in lines {
			let range = NSRange(line.startIndex..., in: line)
			if let match = timestampPattern.firstMatch(in: line, range: range),
			   let tsRange = Range(match.range(at: 1), in: line) {
				if let timestamp = currentTimestamp {
					let content = trimEntryContent(currentContentLines)
					entries.append(Entry(timestamp: timestamp, content: content))
				}
				currentTimestamp = String(line[tsRange])
				currentContentLines = []
			} else if currentTimestamp != nil {
				currentContentLines.append(line)
			}
		}

		if let timestamp = currentTimestamp {
			let content = trimEntryContent(currentContentLines)
			entries.append(Entry(timestamp: timestamp, content: content))
		}

		return entries
	}

	private static func trimEntryContent(_ lines: [String]) -> String {
		var result = lines.joined(separator: "\n")

		// Trim leading and trailing blank lines
		while result.hasPrefix("\n") {
			result.removeFirst()
		}
		while result.hasSuffix("\n") {
			result.removeLast()
		}

		return result
	}
}
