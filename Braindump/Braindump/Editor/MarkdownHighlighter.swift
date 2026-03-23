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
					// Apply per-language highlighting inside code blocks
					applySyntaxHighlighting(to: textStorage, in: matchRange, text: text)
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

	// MARK: - Per-Language Syntax Highlighting

	private static let sqlKeywords = try! NSRegularExpression(
		pattern: "\\b(SELECT|FROM|WHERE|INSERT|INTO|UPDATE|SET|DELETE|JOIN|LEFT|RIGHT|INNER|OUTER|ON|AND|OR|NOT|IN|IS|NULL|AS|ORDER|BY|GROUP|HAVING|LIMIT|OFFSET|CREATE|TABLE|ALTER|DROP|INDEX|VALUES|DISTINCT|UNION|ALL|EXISTS|BETWEEN|LIKE|COUNT|SUM|AVG|MIN|MAX|CASE|WHEN|THEN|ELSE|END)\\b",
		options: [.caseInsensitive]
	)

	private static let stringPattern = try! NSRegularExpression(
		pattern: "'[^']*'|\"[^\"]*\"",
		options: []
	)

	private static let numberPattern = try! NSRegularExpression(
		pattern: "\\b\\d+\\.?\\d*\\b",
		options: []
	)

	private func applySyntaxHighlighting(to textStorage: NSTextStorage, in range: NSRange, text: String) {
		// Extract the code block content (skip opening ``` line)
		let blockText = (text as NSString).substring(with: range)
		let firstLine = blockText.components(separatedBy: "\n").first?.lowercased() ?? ""

		// Detect language from opening fence
		let language: String?
		if firstLine.hasPrefix("```") {
			language = String(firstLine.dropFirst(3)).trimmingCharacters(in: .whitespaces)
		} else {
			language = nil
		}

		guard let lang = language, !lang.isEmpty else { return }

		// Apply language-specific patterns
		let patterns: [(NSRegularExpression, TokenKind)]
		switch lang {
		case "sql":
			patterns = [
				(Self.sqlKeywords, .keyword),
				(Self.stringPattern, .string),
				(Self.numberPattern, .number),
			]
		default:
			patterns = [
				(Self.stringPattern, .string),
				(Self.numberPattern, .number),
			]
		}

		for (regex, tokenKind) in patterns {
			let matches = regex.matches(in: text, range: range)
			for match in matches {
				guard let style = theme.styles[tokenKind] else { continue }
				textStorage.addAttribute(.foregroundColor, value: style.foregroundColor, range: match.range)
				if let font = style.font {
					textStorage.addAttribute(.font, value: font, range: match.range)
				}
			}
		}
	}
}
