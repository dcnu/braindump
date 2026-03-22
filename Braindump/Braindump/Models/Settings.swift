import Foundation

enum SortKey: String, CaseIterable {
	case created
	case edited
}

enum TimeFormat: String, CaseIterable {
	case h24 = "24h"
	case h12 = "12h"
}

enum EntryOrder: String, CaseIterable {
	case chronological
	case reverseChronological
}

enum TimestampMode: String, CaseIterable {
	case perBlock
	case perLine
}

enum AppearanceMode: String, CaseIterable {
	case system
	case light
	case dark
}

struct KeyCombo: Equatable {
	var key: UInt16
	var modifiers: UInt

	static let defaultHotkey = KeyCombo(key: 49, modifiers: 262144) // Ctrl+Space
}

@Observable
final class AppSettings {
	var sortKey: SortKey {
		get { SortKey(rawValue: UserDefaults.standard.string(forKey: "sortKey") ?? "created") ?? .created }
		set { UserDefaults.standard.set(newValue.rawValue, forKey: "sortKey") }
	}

	var vaultPath: String {
		get { UserDefaults.standard.string(forKey: "vaultPath") ?? defaultVaultPath() }
		set { UserDefaults.standard.set(newValue, forKey: "vaultPath") }
	}

	var timeFormat: TimeFormat {
		get { TimeFormat(rawValue: UserDefaults.standard.string(forKey: "timeFormat") ?? "24h") ?? .h24 }
		set { UserDefaults.standard.set(newValue.rawValue, forKey: "timeFormat") }
	}

	var entryOrder: EntryOrder {
		get { EntryOrder(rawValue: UserDefaults.standard.string(forKey: "entryOrder") ?? "reverseChronological") ?? .reverseChronological }
		set { UserDefaults.standard.set(newValue.rawValue, forKey: "entryOrder") }
	}

	var timestampMode: TimestampMode {
		get { TimestampMode(rawValue: UserDefaults.standard.string(forKey: "timestampMode") ?? "perBlock") ?? .perBlock }
		set { UserDefaults.standard.set(newValue.rawValue, forKey: "timestampMode") }
	}

	var appearanceMode: AppearanceMode {
		get { AppearanceMode(rawValue: UserDefaults.standard.string(forKey: "appearanceMode") ?? "system") ?? .system }
		set { UserDefaults.standard.set(newValue.rawValue, forKey: "appearanceMode") }
	}

	var dayStartHour: Int {
		get {
			let value = UserDefaults.standard.integer(forKey: "dayStartHour")
			return UserDefaults.standard.object(forKey: "dayStartHour") != nil ? value : Constants.defaultDayStartHour
		}
		set { UserDefaults.standard.set(newValue, forKey: "dayStartHour") }
	}

	var launchAtLogin: Bool {
		get { UserDefaults.standard.bool(forKey: "launchAtLogin") }
		set { UserDefaults.standard.set(newValue, forKey: "launchAtLogin") }
	}

	var braindumpURL: URL {
		let base = URL(fileURLWithPath: (vaultPath as NSString).expandingTildeInPath)
		return base.appendingPathComponent(Constants.braindumpDirectory)
	}

	private func defaultVaultPath() -> String {
		let home = NSHomeDirectory()
		return "\(home)/Documents/Obsidian"
	}
}
