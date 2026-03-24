import SwiftUI
import AppKit

struct AutoClosingTextEditor: NSViewRepresentable {
	@Binding var text: String
	var onSubmit: (() -> Void)?
	var isEditable: Bool = true
	var autoCorrect: Bool = false
	var shouldFocus: Bool = false
	var fontColorHex: String = "#000000"

	func makeNSView(context: Context) -> NSScrollView {
		let scrollView = NSScrollView()
		scrollView.hasVerticalScroller = false
		scrollView.hasHorizontalScroller = false
		scrollView.drawsBackground = false
		scrollView.borderType = .noBorder
		scrollView.autoresizingMask = [.width, .height]

		let textView = BraindumpTextView()
		textView.isEditable = isEditable
		textView.drawsBackground = false
		textView.string = text
		textView.isAutomaticSpellingCorrectionEnabled = autoCorrect
		textView.autoresizingMask = [.width]

		textView.minSize = NSSize(width: 0, height: 0)
		textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

		textView.onTextChange = { newText in
			Task { @MainActor in
				context.coordinator.isUpdating = true
				self.text = newText
				context.coordinator.isUpdating = false
			}
		}

		textView.onSubmit = {
			onSubmit?()
		}

		scrollView.documentView = textView
		context.coordinator.textView = textView
		context.coordinator.scrollView = scrollView

		return scrollView
	}

	func updateNSView(_ nsView: NSScrollView, context: Context) {
		guard let textView = context.coordinator.textView else { return }
		guard !context.coordinator.isUpdating else { return }

		if textView.string != text {
			let cursorPos = textView.selectedRange().location
			textView.string = text
			if let storage = textView.textStorage {
				textView.markdownHighlighter.applyHighlighting(to: storage)
			}
			let safeCursor = min(cursorPos, textView.string.count)
			textView.setSelectedRange(NSRange(location: safeCursor, length: 0))
		}

		textView.isEditable = isEditable
		textView.isAutomaticSpellingCorrectionEnabled = autoCorrect
		let hex = fontColorHex
		textView.textColor = NSColor(
			red: CGFloat(Int(hex.dropFirst().prefix(2), radix: 16) ?? 0) / 255,
			green: CGFloat(Int(hex.dropFirst(3).prefix(2), radix: 16) ?? 0) / 255,
			blue: CGFloat(Int(hex.dropFirst(5).prefix(2), radix: 16) ?? 0) / 255,
			alpha: 1
		)

		if let scrollWidth = textView.enclosingScrollView?.contentSize.width, scrollWidth > 0 {
			textView.frame.size.width = scrollWidth
			textView.textContainer?.containerSize = NSSize(width: scrollWidth, height: CGFloat.greatestFiniteMagnitude)
		}

		// One-shot focus: make first responder once, then stop
		if shouldFocus && !context.coordinator.didFocus {
			context.coordinator.didFocus = true
			DispatchQueue.main.async {
				textView.window?.makeFirstResponder(textView)
			}
		}
	}

	func makeCoordinator() -> Coordinator {
		Coordinator()
	}

	final class Coordinator {
		var textView: BraindumpTextView?
		var scrollView: NSScrollView?
		var isUpdating = false
		var didFocus = false
	}
}
