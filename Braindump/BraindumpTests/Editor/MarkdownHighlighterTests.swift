import XCTest
import AppKit
@testable import Braindump

final class MarkdownHighlighterTests: XCTestCase {
	private var textStorage: NSTextStorage!
	private var highlighter: MarkdownHighlighter!

	override func setUp() {
		super.setUp()
		highlighter = MarkdownHighlighter()
		textStorage = NSTextStorage()
		textStorage.delegate = highlighter
	}

	private func setAndHighlight(_ text: String) {
		textStorage.replaceCharacters(in: NSRange(location: 0, length: textStorage.length), with: text)
	}

	private func foregroundColor(at location: Int) -> NSColor? {
		guard location < textStorage.length else { return nil }
		return textStorage.attribute(.foregroundColor, at: location, effectiveRange: nil) as? NSColor
	}

	private func backgroundColor(at location: Int) -> NSColor? {
		guard location < textStorage.length else { return nil }
		return textStorage.attribute(.backgroundColor, at: location, effectiveRange: nil) as? NSColor
	}

	// MARK: - Bold

	func testBoldHighlighting() {
		setAndHighlight("some **bold** text")
		let boldColor = highlighter.theme.styles[.bold]!.foregroundColor
		// "**bold**" starts at index 5
		XCTAssertEqual(foregroundColor(at: 5), boldColor)
		XCTAssertEqual(foregroundColor(at: 11), boldColor)
	}

	// MARK: - Italic

	func testItalicHighlighting() {
		setAndHighlight("some *italic* text")
		let italicColor = highlighter.theme.styles[.italic]!.foregroundColor
		XCTAssertEqual(foregroundColor(at: 5), italicColor)
	}

	// MARK: - Inline Code

	func testInlineCodeHighlighting() {
		setAndHighlight("use `code` here")
		let codeColor = highlighter.theme.styles[.inlineCode]!.foregroundColor
		// "`code`" starts at index 4
		XCTAssertEqual(foregroundColor(at: 4), codeColor)
		XCTAssertNotNil(backgroundColor(at: 5))
	}

	// MARK: - Code Block

	func testCodeBlockHighlighting() {
		setAndHighlight("```swift\nlet x = 1\n```")
		let codeColor = highlighter.theme.styles[.codeBlock]!.foregroundColor
		XCTAssertEqual(foregroundColor(at: 0), codeColor)
		XCTAssertNotNil(backgroundColor(at: 5))
	}

	func testCodeBlockSuppressesInnerPatterns() {
		setAndHighlight("```\n**bold** inside code\n```")
		let codeColor = highlighter.theme.styles[.codeBlock]!.foregroundColor
		// "**bold**" at index 4 should have code block color, not bold color
		XCTAssertEqual(foregroundColor(at: 4), codeColor)
	}

	// MARK: - Strikethrough

	func testStrikethroughHighlighting() {
		setAndHighlight("some ~~struck~~ text")
		let strikeColor = highlighter.theme.styles[.strikethrough]!.foregroundColor
		XCTAssertEqual(foregroundColor(at: 5), strikeColor)

		let strikeAttr = textStorage.attribute(.strikethroughStyle, at: 6, effectiveRange: nil) as? Int
		XCTAssertEqual(strikeAttr, NSUnderlineStyle.single.rawValue)
	}

	// MARK: - Tasks

	func testOpenTaskHighlighting() {
		setAndHighlight("- [ ] do something")
		let taskColor = highlighter.theme.styles[.taskOpen]!.foregroundColor
		XCTAssertEqual(foregroundColor(at: 0), taskColor)
	}

	func testDoneTaskHighlighting() {
		setAndHighlight("- [x] done thing")
		let taskColor = highlighter.theme.styles[.taskDone]!.foregroundColor
		XCTAssertEqual(foregroundColor(at: 0), taskColor)
	}

	func testAlternateTaskSyntax() {
		setAndHighlight("- [] also a task")
		let taskColor = highlighter.theme.styles[.taskOpen]!.foregroundColor
		XCTAssertEqual(foregroundColor(at: 0), taskColor)
	}

	// MARK: - Wikilinks

	func testWikilinkHighlighting() {
		setAndHighlight("see [[some-note]] here")
		let wikiColor = highlighter.theme.styles[.wikilink]!.foregroundColor
		// "[[some-note]]" starts at index 4
		XCTAssertEqual(foregroundColor(at: 4), wikiColor)
		XCTAssertEqual(foregroundColor(at: 16), wikiColor)
	}

	// MARK: - Blockquotes

	func testBlockquoteHighlighting() {
		setAndHighlight("> this is a quote")
		let quoteColor = highlighter.theme.styles[.blockquote]!.foregroundColor
		XCTAssertEqual(foregroundColor(at: 0), quoteColor)
	}

	// MARK: - Tags

	func testTagHighlighting() {
		setAndHighlight("note about #topic here")
		let tagColor = highlighter.theme.styles[.tag]!.foregroundColor
		// "#topic" starts at index 11
		XCTAssertEqual(foregroundColor(at: 11), tagColor)
	}

	// MARK: - Headings

	func testHeadingHighlighting() {
		setAndHighlight("## 14:30:00")
		let headingColor = highlighter.theme.styles[.heading]!.foregroundColor
		XCTAssertEqual(foregroundColor(at: 0), headingColor)
	}

	// MARK: - Mixed Content

	func testMixedContent() {
		setAndHighlight("**bold** and `code` and #tag")
		let boldColor = highlighter.theme.styles[.bold]!.foregroundColor
		let codeColor = highlighter.theme.styles[.inlineCode]!.foregroundColor
		let tagColor = highlighter.theme.styles[.tag]!.foregroundColor

		XCTAssertEqual(foregroundColor(at: 0), boldColor)
		XCTAssertEqual(foregroundColor(at: 13), codeColor)
		// "**bold** and `code` and #tag" — # is at index 24
		XCTAssertEqual(foregroundColor(at: 24), tagColor)
	}

	// MARK: - Plain Text

	func testPlainTextUsesBaseColor() {
		setAndHighlight("just plain text")
		XCTAssertEqual(foregroundColor(at: 0), highlighter.theme.baseColor)
	}
}
