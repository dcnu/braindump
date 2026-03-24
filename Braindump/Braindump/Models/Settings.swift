import Foundation
import AppKit

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

enum AppearanceMode: String, CaseIterable {
	case system
	case light
	case dark
}

struct KeyCombo: Equatable {
	var key: UInt16
	var modifiers: UInt

	static let defaultHotkey = KeyCombo(key: 49, modifiers: 393475)

	var displayString: String {
		var parts: [String] = []
		let mods = NSEvent.ModifierFlags(rawValue: modifiers)
		if mods.contains(.control) { parts.append("Ctrl") }
		if mods.contains(.option) { parts.append("Opt") }
		if mods.contains(.shift) { parts.append("Shift") }
		if mods.contains(.command) { parts.append("CMD") }
		parts.append(KeyCombo.keyName(for: key))
		return parts.joined(separator: " + ")
	}

	static func keyName(for keyCode: UInt16) -> String {
		let names: [UInt16: String] = [
			0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
			8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
			16: "Y", 17: "T", 31: "O", 32: "U", 34: "I", 35: "P", 37: "L",
			38: "J", 40: "K", 45: "N", 46: "M",
			18: "1", 19: "2", 20: "3", 21: "4", 23: "5", 22: "6", 26: "7",
			28: "8", 25: "9", 29: "0",
			36: "Return", 48: "Tab", 49: "Space", 51: "Delete", 53: "Escape",
			123: "Left", 124: "Right", 125: "Down", 126: "Up",
		]
		return names[keyCode] ?? "Key(\(keyCode))"
	}
}

@Observable
final class AppSettings {
	let defaults: UserDefaults

	init(defaults: UserDefaults = .standard) {
		self.defaults = defaults
	}

	var sortKey: SortKey {
		get { SortKey(rawValue: defaults.string(forKey: "sortKey") ?? "created") ?? .created }
		set { defaults.set(newValue.rawValue, forKey: "sortKey") }
	}

	var vaultPath: String {
		get { defaults.string(forKey: "vaultPath") ?? defaultVaultPath() }
		set { defaults.set(newValue, forKey: "vaultPath") }
	}

	var timeFormat: TimeFormat {
		get { TimeFormat(rawValue: defaults.string(forKey: "timeFormat") ?? "24h") ?? .h24 }
		set { defaults.set(newValue.rawValue, forKey: "timeFormat") }
	}

	var entryOrder: EntryOrder {
		get { EntryOrder(rawValue: defaults.string(forKey: "entryOrder") ?? "reverseChronological") ?? .reverseChronological }
		set { defaults.set(newValue.rawValue, forKey: "entryOrder") }
	}

	var globalHotkey: KeyCombo {
		get {
			let key = defaults.object(forKey: "hotkeyKeyCode") as? Int
			let mods = defaults.object(forKey: "hotkeyModifiers") as? Int
			if let key, let mods {
				return KeyCombo(key: UInt16(key), modifiers: UInt(mods))
			}
			return KeyCombo.defaultHotkey
		}
		set {
			defaults.set(Int(newValue.key), forKey: "hotkeyKeyCode")
			defaults.set(Int(newValue.modifiers), forKey: "hotkeyModifiers")
		}
	}

	var enterSubmits: Bool {
		get { defaults.object(forKey: "enterSubmits") != nil ? defaults.bool(forKey: "enterSubmits") : false }
		set { defaults.set(newValue, forKey: "enterSubmits") }
	}

	var autoCapitalize: Bool {
		get { defaults.object(forKey: "autoCapitalize") != nil ? defaults.bool(forKey: "autoCapitalize") : true }
		set { defaults.set(newValue, forKey: "autoCapitalize") }
	}

	var autoCorrect: Bool {
		get { defaults.object(forKey: "autoCorrect") != nil ? defaults.bool(forKey: "autoCorrect") : false }
		set { defaults.set(newValue, forKey: "autoCorrect") }
	}

	var fontColorHex: String {
		get { defaults.string(forKey: "fontColorHex") ?? "#000000" }
		set { defaults.set(newValue, forKey: "fontColorHex") }
	}

	var headerColorHex: String {
		get { defaults.string(forKey: "headerColorHex") ?? "#1a1a1a" }
		set { defaults.set(newValue, forKey: "headerColorHex") }
	}

	var backgroundColorHex: String {
		get { defaults.string(forKey: "backgroundColorHex") ?? "#ffffff" }
		set { defaults.set(newValue, forKey: "backgroundColorHex") }
	}

	var appearanceMode: AppearanceMode {
		get { AppearanceMode(rawValue: defaults.string(forKey: "appearanceMode") ?? "system") ?? .system }
		set { defaults.set(newValue.rawValue, forKey: "appearanceMode") }
	}

	var dayStartHour: Int {
		get {
			let value = defaults.integer(forKey: "dayStartHour")
			return defaults.object(forKey: "dayStartHour") != nil ? value : Constants.defaultDayStartHour
		}
		set { defaults.set(newValue, forKey: "dayStartHour") }
	}

	var launchAtLogin: Bool {
		get { defaults.bool(forKey: "launchAtLogin") }
		set { defaults.set(newValue, forKey: "launchAtLogin") }
	}

	var fontName: String {
		get { defaults.string(forKey: "fontName") ?? "SF Mono" }
		set { defaults.set(newValue, forKey: "fontName") }
	}

	var fontSize: Double {
		get {
			let value = defaults.double(forKey: "fontSize")
			return value > 0 ? value : 13
		}
		set { defaults.set(newValue, forKey: "fontSize") }
	}

	var braindumpURL: URL {
		let base = URL(fileURLWithPath: (vaultPath as NSString).expandingTildeInPath)
		return base.appendingPathComponent(Constants.braindumpDirectory)
	}

	func resetToDefaults() {
		let keysToReset = [
			"sortKey", "timeFormat", "entryOrder",
			"appearanceMode", "dayStartHour", "launchAtLogin",
			"fontName", "fontSize", "enterSubmits", "autoCapitalize", "autoCorrect",
			"fontColorHex", "headerColorHex", "backgroundColorHex",
			"hotkeyKeyCode", "hotkeyModifiers",
		]
		for key in keysToReset {
			defaults.removeObject(forKey: key)
		}
	}

	private func defaultVaultPath() -> String {
		let home = NSHomeDirectory()
		return "\(home)/Documents/Obsidian"
	}
}
