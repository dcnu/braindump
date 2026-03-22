import AppKit

final class BraindumpTextView: NSTextView {
	var onTextChange: ((String) -> Void)?
	var onSubmit: (() -> Void)?

	let markdownHighlighter = MarkdownHighlighter()

	convenience init() {
		let textStorage = NSTextStorage()
		let layoutManager = NSLayoutManager()
		textStorage.addLayoutManager(layoutManager)
		let textContainer = NSTextContainer()
		textContainer.widthTracksTextView = true
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
		textContainer?.widthTracksTextView = true
	}

	override func didChangeText() {
		super.didChangeText()
		onTextChange?(string)
	}

	override func keyDown(with event: NSEvent) {
		if event.modifierFlags.contains(.command) && event.keyCode == 36 {
			onSubmit?()
			return
		}

		super.keyDown(with: event)
	}

	override func paste(_ sender: Any?) {
		guard let pasteboard = NSPasteboard.general.string(forType: .string) else {
			super.paste(sender)
			return
		}

		let normalized = normalizePastedText(pasteboard)
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
