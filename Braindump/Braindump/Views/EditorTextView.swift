import SwiftUI
import AppKit

struct EditorTextView: NSViewRepresentable {
	@Binding var text: String
	var onSubmit: (() -> Void)?
	var isEditable: Bool = true

	func makeNSView(context: Context) -> NSScrollView {
		let scrollView = NSScrollView()
		scrollView.hasVerticalScroller = false
		scrollView.hasHorizontalScroller = false
		scrollView.drawsBackground = false
		scrollView.borderType = .noBorder

		let textView = BraindumpTextView()
		textView.minSize = NSSize(width: 0, height: 0)
		textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
		textView.isEditable = isEditable
		textView.drawsBackground = false
		textView.string = text

		textView.onTextChange = { newText in
			DispatchQueue.main.async {
				self.text = newText
			}
		}

		textView.onSubmit = {
			onSubmit?()
		}

		scrollView.documentView = textView
		context.coordinator.textView = textView

		// Force initial highlighting
		if let storage = textView.textStorage {
			textView.markdownHighlighter.applyHighlighting(to: storage)
		}

		return scrollView
	}

	func updateNSView(_ nsView: NSScrollView, context: Context) {
		guard let textView = context.coordinator.textView else { return }

		if textView.string != text {
			let selectedRange = textView.selectedRange()
			textView.string = text
			if let storage = textView.textStorage {
				textView.markdownHighlighter.applyHighlighting(to: storage)
			}
			let safeRange = NSRange(
				location: min(selectedRange.location, textView.string.count),
				length: 0
			)
			textView.setSelectedRange(safeRange)
		}

		textView.isEditable = isEditable

		// Ensure text color stays correct when appearance changes
		textView.textColor = .labelColor
	}

	func makeCoordinator() -> Coordinator {
		Coordinator()
	}

	final class Coordinator {
		var textView: BraindumpTextView?
	}
}
