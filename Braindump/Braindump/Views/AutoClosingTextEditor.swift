import SwiftUI
import AppKit

struct AutoClosingTextEditor: NSViewRepresentable {
	@Binding var text: String
	var onSubmit: (() -> Void)?
	var isEditable: Bool = true
	var autoCorrect: Bool = false

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

		// Critical sizing fix: text view must fill the scroll view width
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

		// Sync text from binding to NSTextView
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
		textView.textColor = .labelColor

		// Ensure text view width matches scroll view
		if let scrollWidth = textView.enclosingScrollView?.contentSize.width, scrollWidth > 0 {
			textView.frame.size.width = scrollWidth
			textView.textContainer?.containerSize = NSSize(width: scrollWidth, height: CGFloat.greatestFiniteMagnitude)
		}
	}

	func makeCoordinator() -> Coordinator {
		Coordinator()
	}

	final class Coordinator {
		var textView: BraindumpTextView?
		var scrollView: NSScrollView?
		var isUpdating = false
	}
}
