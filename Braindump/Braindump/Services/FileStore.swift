import Foundation

final class FileStore {
	let baseURL: URL

	init(baseURL: URL) {
		self.baseURL = baseURL
	}

	func ensureDirectoryExists() throws {
		try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
	}

	func loadDailyFile(for date: String) throws -> DailyFile? {
		let fileURL = url(for: date)
		guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
		let content = try String(contentsOf: fileURL, encoding: .utf8)
		return DailyFile.parse(markdown: content)
	}

	func saveDailyFile(_ file: DailyFile) throws {
		try ensureDirectoryExists()
		let fileURL = url(for: file.frontMatter.created)
		let content = DailyFile.serialize(file)
		try content.data(using: .utf8)?.write(to: fileURL, options: .atomic)
	}

	func deleteDailyFile(for date: String) throws {
		let fileURL = url(for: date)
		if FileManager.default.fileExists(atPath: fileURL.path) {
			try FileManager.default.removeItem(at: fileURL)
		}
	}

	func listDailyFiles() throws -> [String] {
		guard FileManager.default.fileExists(atPath: baseURL.path) else { return [] }
		let contents = try FileManager.default.contentsOfDirectory(
			at: baseURL,
			includingPropertiesForKeys: nil
		)
		return contents
			.filter { $0.pathExtension == Constants.fileExtension }
			.map { $0.deletingPathExtension().lastPathComponent }
			.filter { isValidDateString($0) }
			.sorted()
	}

	// MARK: - Private

	private func url(for date: String) -> URL {
		baseURL.appendingPathComponent("\(date).\(Constants.fileExtension)")
	}

	private func isValidDateString(_ string: String) -> Bool {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd"
		return formatter.date(from: string) != nil
	}
}
