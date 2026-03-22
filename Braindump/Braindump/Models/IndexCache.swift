import Foundation

struct IndexEntry: Codable, Equatable {
	let date: String
	let filePath: String
	let status: String
	let entryCount: Int
	let lastEntryTime: String
}
