import Foundation

final class IndexManager {
	private let store: FileStore

	init(store: FileStore) {
		self.store = store
	}

	func rebuildIndex() throws -> [IndexEntry] {
		let dates = try store.listDailyFiles()
		return try dates.compactMap { date in
			try buildIndexEntry(for: date)
		}
	}

	func writeIndex(_ entries: [IndexEntry], to url: URL) throws {
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
		let data = try encoder.encode(entries)
		try data.write(to: url, options: .atomic)
	}

	func readIndex(from url: URL) throws -> [IndexEntry] {
		guard FileManager.default.fileExists(atPath: url.path) else { return [] }
		let data = try Data(contentsOf: url)
		return try JSONDecoder().decode([IndexEntry].self, from: data)
	}

	func reconcile(current: [IndexEntry]) throws -> [IndexEntry] {
		let freshIndex = try rebuildIndex()
		return freshIndex
	}

	// MARK: - Private

	private func buildIndexEntry(for date: String) throws -> IndexEntry? {
		guard let file = try store.loadDailyFile(for: date) else { return nil }

		let lastTime = file.entries.last?.timestamp ?? ""

		return IndexEntry(
			date: date,
			filePath: "\(Constants.braindumpDirectory)/\(date).\(Constants.fileExtension)",
			status: file.frontMatter.status.rawValue,
			entryCount: file.entries.count,
			lastEntryTime: lastTime
		)
	}
}
