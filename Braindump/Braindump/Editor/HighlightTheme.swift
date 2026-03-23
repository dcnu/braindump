import AppKit

enum TokenKind: CaseIterable {
	case codeBlock
	case inlineCode
	case bold
	case italic
	case strikethrough
	case taskOpen
	case taskDone
	case wikilink
	case blockquote
	case tag
	case heading
	case keyword
	case string
	case number
}

struct HighlightTheme {
	struct TokenStyle {
		let foregroundColor: NSColor
		let font: NSFont?
		let backgroundColor: NSColor?

		init(foregroundColor: NSColor, font: NSFont? = nil, backgroundColor: NSColor? = nil) {
			self.foregroundColor = foregroundColor
			self.font = font
			self.backgroundColor = backgroundColor
		}
	}

	let styles: [TokenKind: TokenStyle]
	let baseFont: NSFont
	let baseColor: NSColor

	static var `default`: HighlightTheme {
		let monoFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
		let boldMono = NSFont.monospacedSystemFont(ofSize: 13, weight: .bold)

		return HighlightTheme(
			styles: [
				.codeBlock: TokenStyle(
					foregroundColor: NSColor.systemGreen,
					font: monoFont,
					backgroundColor: NSColor.quaternaryLabelColor
				),
				.inlineCode: TokenStyle(
					foregroundColor: NSColor.systemGreen,
					font: monoFont,
					backgroundColor: NSColor.quaternaryLabelColor
				),
				.bold: TokenStyle(
					foregroundColor: NSColor.labelColor,
					font: boldMono
				),
				.italic: TokenStyle(
					foregroundColor: NSColor.labelColor,
					font: NSFontManager.shared.convert(monoFont, toHaveTrait: .italicFontMask)
				),
				.strikethrough: TokenStyle(
					foregroundColor: NSColor.secondaryLabelColor
				),
				.taskOpen: TokenStyle(
					foregroundColor: NSColor.systemOrange
				),
				.taskDone: TokenStyle(
					foregroundColor: NSColor.systemGreen
				),
				.wikilink: TokenStyle(
					foregroundColor: NSColor.systemBlue
				),
				.blockquote: TokenStyle(
					foregroundColor: NSColor.secondaryLabelColor,
					font: NSFontManager.shared.convert(monoFont, toHaveTrait: .italicFontMask)
				),
				.tag: TokenStyle(
					foregroundColor: NSColor.systemPurple
				),
				.heading: TokenStyle(
					foregroundColor: NSColor.labelColor,
					font: boldMono
				),
				.keyword: TokenStyle(
					foregroundColor: NSColor.systemBlue,
					font: boldMono
				),
				.string: TokenStyle(
					foregroundColor: NSColor.systemGreen
				),
				.number: TokenStyle(
					foregroundColor: NSColor.systemOrange
				),
			],
			baseFont: monoFont,
			baseColor: NSColor.labelColor
		)
	}
}
