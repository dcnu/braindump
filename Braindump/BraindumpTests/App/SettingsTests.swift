import XCTest
@testable import Braindump

final class SettingsTests: XCTestCase {
	var settings: AppSettings!

	override func setUp() {
		super.setUp()
		settings = AppSettings()
		settings.resetToDefaults()
	}

	override func tearDown() {
		settings.resetToDefaults()
		super.tearDown()
	}

	// MARK: - Default values

	func testDefaultFontColor() {
		XCTAssertEqual(settings.fontColorHex, "#000000")
	}

	func testDefaultHeaderColor() {
		XCTAssertEqual(settings.headerColorHex, "#1a1a1a")
	}

	func testDefaultBackgroundColor() {
		XCTAssertEqual(settings.backgroundColorHex, "#ffffff")
	}

	func testDefaultFontName() {
		XCTAssertEqual(settings.fontName, "SF Mono")
	}

	func testDefaultFontSize() {
		XCTAssertEqual(settings.fontSize, 13)
	}

	func testDefaultAutoCapitalize() {
		XCTAssertTrue(settings.autoCapitalize)
	}

	func testDefaultAutoCorrect() {
		XCTAssertFalse(settings.autoCorrect)
	}

	func testDefaultEnterSubmits() {
		XCTAssertFalse(settings.enterSubmits)
	}

	func testDefaultTimeFormat() {
		XCTAssertEqual(settings.timeFormat, .h24)
	}

	func testDefaultDayStartHour() {
		XCTAssertEqual(settings.dayStartHour, 2)
	}

	func testDefaultAppearanceMode() {
		XCTAssertEqual(settings.appearanceMode, .system)
	}

	// MARK: - Persistence

	func testFontColorPersists() {
		settings.fontColorHex = "#FF0000"
		let fresh = AppSettings()
		XCTAssertEqual(fresh.fontColorHex, "#FF0000")
	}

	func testHeaderColorPersists() {
		settings.headerColorHex = "#00FF00"
		let fresh = AppSettings()
		XCTAssertEqual(fresh.headerColorHex, "#00FF00")
	}

	func testBackgroundColorPersists() {
		settings.backgroundColorHex = "#0000FF"
		let fresh = AppSettings()
		XCTAssertEqual(fresh.backgroundColorHex, "#0000FF")
	}

	func testFontNamePersists() {
		settings.fontName = "Menlo"
		let fresh = AppSettings()
		XCTAssertEqual(fresh.fontName, "Menlo")
	}

	func testFontSizePersists() {
		settings.fontSize = 18
		let fresh = AppSettings()
		XCTAssertEqual(fresh.fontSize, 18)
	}

	func testAutoCapitalizePersists() {
		settings.autoCapitalize = false
		let fresh = AppSettings()
		XCTAssertFalse(fresh.autoCapitalize)
	}

	func testAutoCorrectPersists() {
		settings.autoCorrect = true
		let fresh = AppSettings()
		XCTAssertTrue(fresh.autoCorrect)
	}

	func testEnterSubmitsPersists() {
		settings.enterSubmits = true
		let fresh = AppSettings()
		XCTAssertTrue(fresh.enterSubmits)
	}

	// MARK: - Reset to defaults

	func testResetToDefaults() {
		settings.fontColorHex = "#FF0000"
		settings.headerColorHex = "#00FF00"
		settings.backgroundColorHex = "#0000FF"
		settings.fontName = "Menlo"
		settings.fontSize = 24
		settings.autoCapitalize = false
		settings.autoCorrect = true
		settings.enterSubmits = true

		settings.resetToDefaults()

		XCTAssertEqual(settings.fontColorHex, "#000000")
		XCTAssertEqual(settings.headerColorHex, "#1a1a1a")
		XCTAssertEqual(settings.backgroundColorHex, "#ffffff")
		XCTAssertEqual(settings.fontName, "SF Mono")
		XCTAssertEqual(settings.fontSize, 13)
		XCTAssertTrue(settings.autoCapitalize)
		XCTAssertFalse(settings.autoCorrect)
		XCTAssertFalse(settings.enterSubmits)
	}

	// MARK: - Hotkey

	func testDefaultHotkey() {
		let combo = settings.globalHotkey
		XCTAssertEqual(combo.key, 49) // Space
		XCTAssertTrue(combo.displayString.contains("Space"))
	}

	func testHotkeyPersists() {
		settings.globalHotkey = KeyCombo(key: 0, modifiers: NSEvent.ModifierFlags.command.rawValue)
		let fresh = AppSettings()
		XCTAssertEqual(fresh.globalHotkey.key, 0)
	}

	// MARK: - braindumpURL

	func testBraindumpURL() {
		settings.vaultPath = "/tmp/test-vault"
		XCTAssertEqual(settings.braindumpURL.path, "/tmp/test-vault/braindump")
	}
}
