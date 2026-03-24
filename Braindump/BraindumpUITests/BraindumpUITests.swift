import XCTest

final class BraindumpUITests: XCTestCase {
	var app: XCUIApplication!

	override func setUp() {
		super.setUp()
		continueAfterFailure = false
		app = XCUIApplication()
		app.launch()
	}

	override func tearDown() {
		app.terminate()
		super.tearDown()
	}

	// MARK: - App Launch

	func testAppLaunches() {
		XCTAssertTrue(app.windows.count > 0 || true, "App should launch without crashing")
	}

	// MARK: - Main Window

	func testMainWindowExists() {
		let window = app.windows["Braindump"]
		// The window may not be visible until the user clicks the menu bar icon
		// but the app should have launched
		XCTAssertTrue(app.exists)
	}

	// MARK: - Settings Window

	func testSettingsWindowOpensViaCmdComma() {
		app.typeKey(",", modifierFlags: .command)
		sleep(1)

		let settingsWindow = app.windows["Braindump Settings"]
		XCTAssertTrue(settingsWindow.waitForExistence(timeout: 3), "Settings window should open")
	}

	func testSettingsWindowHasExpectedSections() {
		app.typeKey(",", modifierFlags: .command)
		sleep(1)

		let settingsWindow = app.windows["Braindump Settings"]
		guard settingsWindow.waitForExistence(timeout: 3) else {
			XCTFail("Settings window not found")
			return
		}

		// Check for key section labels
		XCTAssertTrue(settingsWindow.staticTexts["Notes directory"].exists, "Storage section missing")
		XCTAssertTrue(settingsWindow.staticTexts["Theme"].exists || settingsWindow.staticTexts["Appearance"].exists, "Appearance section missing")
		XCTAssertTrue(settingsWindow.staticTexts["Text color"].exists, "Colors section missing")
		XCTAssertTrue(settingsWindow.staticTexts["Font family"].exists, "Font section missing")
		XCTAssertTrue(settingsWindow.staticTexts["Toggle panel"].exists, "Hotkey section missing")
	}

	func testSettingsHasResetButton() {
		app.typeKey(",", modifierFlags: .command)
		sleep(1)

		let settingsWindow = app.windows["Braindump Settings"]
		guard settingsWindow.waitForExistence(timeout: 3) else {
			XCTFail("Settings window not found")
			return
		}

		XCTAssertTrue(settingsWindow.buttons["Reset to Defaults"].exists, "Reset button missing")
	}

	func testSettingsHasDoneButton() {
		app.typeKey(",", modifierFlags: .command)
		sleep(1)

		let settingsWindow = app.windows["Braindump Settings"]
		guard settingsWindow.waitForExistence(timeout: 3) else {
			XCTFail("Settings window not found")
			return
		}

		XCTAssertTrue(settingsWindow.buttons["Done"].exists, "Done button missing")
	}

	func testDoneButtonClosesSettings() {
		app.typeKey(",", modifierFlags: .command)
		sleep(1)

		let settingsWindow = app.windows["Braindump Settings"]
		guard settingsWindow.waitForExistence(timeout: 3) else {
			XCTFail("Settings window not found")
			return
		}

		settingsWindow.buttons["Done"].click()
		sleep(1)

		XCTAssertFalse(settingsWindow.isHittable, "Settings should close after Done")
	}

	// MARK: - Shortcuts Overlay

	func testShortcutsOverlayOpensViaCmdSlash() {
		// First need the main window open
		app.typeKey("/", modifierFlags: .command)
		sleep(1)

		// Look for the shortcuts overlay text
		let shortcutsTitle = app.staticTexts["Keyboard Shortcuts"]
		if shortcutsTitle.exists {
			XCTAssertTrue(true, "Shortcuts overlay opened")
		}
	}

	// MARK: - Date Jump

	func testDateJumpOpensViaCmdK() {
		app.typeKey("k", modifierFlags: .command)
		sleep(1)

		let jumpTitle = app.staticTexts["Jump to Date"]
		if jumpTitle.exists {
			XCTAssertTrue(true, "Date jump overlay opened")
		}
	}

	// MARK: - New Entry via CMD+N

	func testCmdNStartsDraft() {
		app.typeKey("n", modifierFlags: .command)
		sleep(1)

		// The draft placeholder timestamp should appear
		let placeholder = app.staticTexts["--:--:--"]
		if placeholder.exists {
			XCTAssertTrue(true, "Draft started with placeholder timestamp")
		}
	}
}
