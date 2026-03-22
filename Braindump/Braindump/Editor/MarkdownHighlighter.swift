import AppKit

final class MarkdownHighlighter: NSObject, NSTextStorageDelegate {
	var theme: HighlightTheme

	private static let patterns: [(kind: TokenKind, pattern: String, options: NSRegularExpression.Options)] = [
		(.codeBlock, "```[\\s\\S]*?```", [.anchorsMatchLines]),
		(.inlineCode, "`[^`]+`", []),
		(.bold, "\\*\\*[^*]+\\*\\*", []),
		(.italic, "(?<!\\*)\\*(?!\\*)[^*]+(?<!\\*)\\*(?!\\*)", []),
		(.strikethrough, "~~[^~]+~~", []),
		(.taskDone, "^- \\[(x|X)\\].*$", [.anchorsMatchLines]),
		(.taskOpen, "^- \\[( |)\\].*$", [.anchorsMatchLines]),
		(.wikilink, "\\[\\[[^\\]]+\\]\\]", []),
		(.blockquote, "^>.*$", [.anchorsMatchLines]),
		(.tag, "(?<=\\s|^)#[a-zA-Z][a-zA-Z0-9_-]*", [.anchorsMatchLines]),
		(.heading, "^##+ .*$", [.anchorsMatchLines]),
	]

	private static let compiledPatterns: [(kind: TokenKind, regex: NSRegularExpression)] = {
		patterns.compactMap { item in
			guard let regex = try? NSRegularExpression(pattern: item.pattern, options: item.options) else {
				return nil
			}
			return (item.kind, regex)
		}
	}()

	init(theme: HighlightTheme = .default) {
		self.theme = theme
		super.init()
	}

	func textStorage(
		_ textStorage: NSTextStorage,
		didProcessEditing editedMask: NSTextStorageEditActions,
		range editedRange: NSRange,
		changeInLength delta: Int
	) {
		guard editedMask.contains(.editedCharacters) else { return }
		applyHighlighting(to: textStorage)
	}

	func applyHighlighting(to textStorage: NSTextStorage) {
		let fullRange = NSRange(location: 0, length: textStorage.length)
		let text = textStorage.string

		// Reset to base style
		textStorage.addAttributes([
			.font: theme.baseFont,
			.foregroundColor: theme.baseColor,
		], range: fullRange)

		// Remove any existing background color
		textStorage.removeAttribute(.backgroundColor, range: fullRange)
		textStorage.removeAttribute(.strikethroughStyle, range: fullRange)

		// Track ranges claimed by code blocks to suppress inner highlighting
		var codeBlockRanges: [NSRange] = []

		for (kind, regex) in Self.compiledPatterns {
			let matches = regex.matches(in: text, range: fullRange)

			for match in matches {
				let matchRange = match.range

				// Skip if this range is inside a code block (unless this is the code block pattern)
				if kind != .codeBlock && kind != .inlineCode {
					if codeBlockRanges.contains(where: { NSIntersectionRange($0, matchRange).length > 0 }) {
						continue
					}
				}

				if kind == .codeBlock {
					codeBlockRanges.append(matchRange)
				}

				guard let style = theme.styles[kind] else { continue }

				textStorage.addAttribute(.foregroundColor, value: style.foregroundColor, range: matchRange)

				if let font = style.font {
					textStorage.addAttribute(.font, value: font, range: matchRange)
				}

				if let bgColor = style.backgroundColor {
					textStorage.addAttribute(.backgroundColor, value: bgColor, range: matchRange)
				}

				if kind == .strikethrough {
					textStorage.addAttribute(
						.strikethroughStyle,
						value: NSUnderlineStyle.single.rawValue,
						range: matchRange
					)
				}
			}
		}
	}
}
