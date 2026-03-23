import AppKit

final class BraindumpTextView: NSTextView {
	var onTextChange: ((String) -> Void)?
	var onSubmit: (() -> Void)?

	let markdownHighlighter = MarkdownHighlighter()

	private static let closingBrackets: [String: String] = [
		"(": ")",
		"[": "]",
		"{": "}",
		"`": "`",
	]

	convenience init() {
		let textStorage = NSTextStorage()
		let layoutManager = NSLayoutManager()
		textStorage.addLayoutManager(layoutManager)
		let textContainer = NSTextContainer()
		textContainer.widthTracksTextView = true
		textContainer.lineFragmentPadding = 4
		layoutManager.addTextContainer(textContainer)
		self.init(frame: .zero, textContainer: textContainer)
	}

	override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
		super.init(frame: frameRect, textContainer: container)
		setup()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setup()
	}

	private func setup() {
		isRichText = false
		isAutomaticQuoteSubstitutionEnabled = false
		isAutomaticDashSubstitutionEnabled = false
		isAutomaticTextReplacementEnabled = false
		isAutomaticSpellingCorrectionEnabled = false
		allowsUndo = true
		usesFindBar = false

		font = markdownHighlighter.theme.baseFont
		textColor = .labelColor
		insertionPointColor = .labelColor
		drawsBackground = false

		textStorage?.delegate = markdownHighlighter

		isVerticallyResizable = true
		isHorizontallyResizable = false
		autoresizingMask = [.width]
		textContainer?.widthTracksTextView = true
	}

	override func didChangeText() {
		super.didChangeText()
		onTextChange?(string)
	}

	// MARK: - Auto-closing brackets

	override func insertText(_ string: Any, replacementRange: NSRange) {
		guard let text = string as? String else {
			super.insertText(string, replacementRange: replacementRange)
			return
		}

		if let closing = Self.closingBrackets[text] {
			super.insertText(text + closing, replacementRange: replacementRange)
			let cursor = selectedRange().location - 1
			if cursor >= 0 {
				setSelectedRange(NSRange(location: cursor, length: 0))
			}
			return
		}

		super.insertText(string, replacementRange: replacementRange)
	}

	// MARK: - Key handling

	override func keyDown(with event: NSEvent) {
		// CMD+Enter to submit
		if event.modifierFlags.contains(.command) && event.keyCode == 36 {
			onSubmit?()
			return
		}

		// CMD+L to insert link
		if event.modifierFlags.contains(.command) && event.keyCode == 37 {
			insertLink()
			return
		}

		super.keyDown(with: event)
	}

	// MARK: - Link insertion

	func insertLink() {
		let selection = selectedRange()
		let selectedText = selection.length > 0
			? (string as NSString).substring(with: selection)
			: ""

		let alert = NSAlert()
		alert.messageText = "Insert Link"
		alert.addButton(withTitle: "Insert")
		alert.addButton(withTitle: "Cancel")

		let container = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 60))

		let textField = NSTextField(frame: NSRect(x: 0, y: 32, width: 300, height: 24))
		textField.placeholderString = "Link text"
		textField.stringValue = selectedText
		container.addSubview(textField)

		let urlField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
		urlField.placeholderString = "https://..."
		container.addSubview(urlField)

		alert.accessoryView = container
		alert.window.initialFirstResponder = selectedText.isEmpty ? textField : urlField

		if alert.runModal() == .alertFirstButtonReturn {
			let linkText = textField.stringValue.isEmpty ? "link" : textField.stringValue
			let url = urlField.stringValue
			guard !url.isEmpty else { return }

			let markdown = "[\(linkText)](\(url))"
			insertText(markdown, replacementRange: selection)
		}
	}

	// MARK: - Paste with URL detection

	override func paste(_ sender: Any?) {
		guard let pasteString = NSPasteboard.general.string(forType: .string) else {
			super.paste(sender)
			return
		}

		// If pasting a URL over a selection, auto-wrap as markdown link
		let selection = selectedRange()
		if selection.length > 0,
		   let url = URL(string: pasteString),
		   let scheme = url.scheme,
		   (scheme == "http" || scheme == "https") {
			let selectedText = (string as NSString).substring(with: selection)
			let markdown = "[\(selectedText)](\(pasteString))"
			insertText(markdown, replacementRange: selection)
			return
		}

		let normalized = normalizePastedText(pasteString)
		insertText(normalized, replacementRange: selectedRange())
	}

	private func normalizePastedText(_ text: String) -> String {
		let lines = text.components(separatedBy: "\n")
		var result: [String] = []
		var lastWasBlank = false

		for line in lines {
			let trimmed = line.replacingOccurrences(
				of: "\\s+$",
				with: "",
				options: .regularExpression
			)
			let isBlank = trimmed.isEmpty

			if isBlank && lastWasBlank {
				continue
			}

			result.append(trimmed)
			lastWasBlank = isBlank
		}

		return result.joined(separator: "\n")
	}
}
